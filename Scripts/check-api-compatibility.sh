#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
baseline="$project_dir/Tests/APICompatibility/EasyDesignSystem-PublicAPI.txt"
work_dir="$(mktemp -d -t eds-api-check)"
removed="$work_dir/removed"

update_baseline=0
if [[ "${1:-}" == "--update-baseline" ]]; then
    update_baseline=1
fi

cd "$project_dir"

count_lines() {
    wc -l < "$1" | tr -d ' '
}

graph_dump() {
    find .build -path "*symbolgraph*" -name "*.symbols.json" | LC_ALL=C sort
}

# 诊断信息既要打到 stdout（本地/CI 日志），也要累积起来写进 GitHub annotation。
# 原因：本仓库的 job 日志接口需要 admin 权限（`/actions/jobs/{id}/logs` 返回 403），
# 公开可读的只有 annotations。不写 annotation，CI 红了就只能看到一句
# "exit code 1"，无从定位。
diag=""
note() {
    echo "$1"
    diag+="$1"$'\n'
}

# GitHub Actions 的 workflow command 要求换行转义为 %0A、`%` 转义为 %25（顺序敏感）。
emit_annotation() {
    local level="$1" title="$2" body="$3"
    [[ "${GITHUB_ACTIONS:-}" == "true" ]] || return 0
    local escaped
    escaped="$(printf '%s' "$body" | sed -e 's/%/%25/g' | awk '{printf "%s%%0A", $0}')"
    echo "::${level} title=${title}::${escaped}"
}

# ─────────────────────────────────────────────────────────────────────────────
# 判据：符号路径（pathComponents），不是 mangled name
# ─────────────────────────────────────────────────────────────────────────────
#
# 曾经用 `.identifier.precise`（mangled name）做判据，结果在 CI 上稳定产生假阳性。
# mangled name 会把**外部模块名**编译进去，例如：
#
#   s:16EasyDesignSystem9EDSButtonV_4role11systemImage6action
#     AC 7SwiftUI 18LocalizedStringKeyV _ AC4RoleO…
#        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 参数类型所属的模块
#   s:16EasyDesignSystem9EDSButtonV_6action5label…7SwiftUI4ViewRz…
#                                              ^^^^^^^^^^^^^^^^^ 泛型约束
#
# Apple 在 Xcode 16 → 27 之间把 SwiftUI 拆成了 SwiftUI + SwiftUICore，同一个类型/
# 协议的 mangling 归属随之变化 → 同一个 commit 在两台机器上算出不同的 identifier，
# 于是"本地过、CI 挂"。实测 CI（Swift 6.1.2 / Xcode 16.4）就报了 3 条 EDSButton 符号
# 被"删除"，而那 3 个符号的代码一行没动。
#
# `pathComponents` 是语言级信息（符号名 + 参数标签），不含外部模块与 mangling 细节，
# 跨 Xcode 版本稳定。代价是检测不到"参数类型变化"——但本脚本的职责是"防止公开符号
# 被删"，类型变化由编译期与单元测试兜底。
#
# 跨模块扩展符号（本模块对 SwiftUI 类型加的 extension）加 `@` 前缀，
# 与本体符号区分，同时避免与本体同名冲突。

collect_paths() {
    local pattern="$1" prefix="$2" out="$3"
    : > "$out"
    # 逐个文件读，不用 `find | xargs`：find 匹配为空时 xargs 什么都不跑，
    # 输出会变成空文件，从而把整份基线误报成"已删除"。
    while IFS= read -r -d '' graph; do
        jq -r --arg p "$prefix" '.symbols[].pathComponents | $p + join(".")' "$graph" >> "$out"
    done < <(find .build -path "$pattern" -print0)
    LC_ALL=C sort -u "$out" -o "$out"
}

# Swift 6.1 may return a failure after successfully emitting library symbol
# graphs because it also tries to load SwiftPM's synthetic PackageTests module.
# Clear old graphs first, then accept that known partial failure only when the
# expected graphs were freshly produced.
find .build -path "*/symbolgraph/*.symbols.json" -delete 2>/dev/null || true
set +e
symbol_graph_output="$(swift package dump-symbol-graph --pretty-print --skip-synthesized-members --minimum-access-level public 2>&1)"
symbol_graph_status=$?
set -e
echo "$symbol_graph_output"

# 这个脚本真正危险的不是"符号被删"，而是"符号图没生成"：
# 后者会让 comm 把**整个基线**判成删除，刷出一屏无效清单，把真正的原因埋掉。
# 因此先做存在性断言。需要两份图：
#   EasyDesignSystem.symbols.json        —— 本体
#   EasyDesignSystem@*.symbols.json      —— 跨模块扩展（对 SwiftUI 类型加的 extension）
core_graph="$(find .build -path "*/symbolgraph/EasyDesignSystem.symbols.json" -print -quit)"
extension_graph="$(find .build -path "*/symbolgraph/EasyDesignSystem@*.symbols.json" -print -quit)"

if [[ -z "$core_graph" || -z "$extension_graph" ]]; then
    diagnostics="$(
        echo "core graph (EasyDesignSystem)        : ${core_graph:-<missing>}"
        echo "extension graph (EasyDesignSystem@*) : ${extension_graph:-<missing>}"
        echo "dump-symbol-graph exit status        : $symbol_graph_status"
        echo "swift: $(swift --version 2>&1 | head -1)"
        echo "xcode: $(xcodebuild -version 2>&1 | head -1)"
        echo "symbolgraph inventory:"
        graph_dump
        echo "--- dump-symbol-graph output (tail 40) ---"
        echo "$symbol_graph_output" | tail -40
    )"
    note "Public API compatibility check failed. Symbol graphs were not generated."
    note "$diagnostics"
    emit_annotation error "API baseline: symbol graphs missing" "$diagnostics"
    exit 1
fi

if [[ "$symbol_graph_status" -ne 0 ]]; then
    note "Ignoring SwiftPM's symbol-graph failure for non-library modules; the expected graphs were generated."
fi

current="$work_dir/current"
collect_paths "*/symbolgraph/EasyDesignSystem.symbols.json"   ""  "$work_dir/current-core"
collect_paths "*/symbolgraph/EasyDesignSystem@*.symbols.json" "@" "$work_dir/current-external"
cat "$work_dir/current-core" "$work_dir/current-external" | LC_ALL=C sort -u > "$current"

if [[ ! -s "$current" ]]; then
    diagnostics="$(
        echo "no public symbol paths were extracted from:"
        graph_dump
    )"
    note "Public API compatibility check failed. No public symbol paths were extracted."
    note "$diagnostics"
    emit_annotation error "API baseline: no symbols extracted" "$diagnostics"
    exit 1
fi

summary="core $(count_lines "$work_dir/current-core") + external $(count_lines "$work_dir/current-external") = $(count_lines "$current") public symbols | toolchain: $(swift --version 2>&1 | head -1)"

if [[ "$update_baseline" -eq 1 ]]; then
    {
        echo "# EasyDesignSystem 公开 API 基线"
        echo "#"
        echo "# 判据是**符号路径**（symbolgraph 的 pathComponents 拼接），不是 mangled name。"
        echo "# 原因：mangled name 会把外部模块名编进去（如 7SwiftUI18LocalizedStringKeyV、"
        echo "# 7SwiftUI4ViewRz），而 Apple 在 Xcode 16 → 27 之间把 SwiftUI 拆出了 SwiftUICore，"
        echo "# 同一个 commit 在不同 Xcode 上会算出不同 identifier，产生"本地过、CI 挂"的假阳性。"
        echo "#"
        echo "# 本模块对 SwiftUI 类型所做扩展的符号带 '@' 前缀，与本体符号区分。"
        echo "#"
        echo "# 更新方式：bash Scripts/check-api-compatibility.sh --update-baseline"
        echo "# 新增符号不会失败；只有在确认要移除公开 API 时才更新基线。"
        cat "$current"
    } > "$baseline"
    note "Baseline updated from $baseline: $(count_lines "$current") symbols."
    note "$summary"
    exit 0
fi

baseline_ids="$work_dir/baseline-ids"
grep -v '^#' "$baseline" | grep -v '^[[:space:]]*$' | LC_ALL=C sort -u > "$baseline_ids"

if [[ ! -s "$baseline_ids" ]]; then
    note "Public API compatibility check failed. Baseline file is empty or missing: $baseline"
    emit_annotation error "API baseline: baseline file empty" "$baseline"
    exit 1
fi

summary="Baseline $(count_lines "$baseline_ids") symbols | current $(count_lines "$current") (core $(count_lines "$work_dir/current-core") + external $(count_lines "$work_dir/current-external")) | toolchain: $(swift --version 2>&1 | head -1) / $(xcodebuild -version 2>&1 | head -1)"
note "$summary"

grep -v '^@' "$baseline_ids" > "$work_dir/baseline-core"
grep '^@'    "$baseline_ids" > "$work_dir/baseline-external"

failed=0

# ① 本体符号：缺失即失败。这是"公开 API 被删"的硬判据。
comm -23 "$work_dir/baseline-core" "$work_dir/current-core" > "$removed"
if [[ -s "$removed" ]]; then
    failed=1
    note "Public API compatibility check failed. Removed public symbols ($(count_lines "$removed")):"
    head -50 "$removed"
    if [[ $(count_lines "$removed") -gt 50 ]]; then
        note "  … $(($(count_lines "$removed") - 50)) more omitted"
    fi
    emit_annotation error "API baseline failed" \
"[removed public symbols: $(count_lines "$removed")]
$(head -40 "$removed")
$summary"
fi

# ② 跨模块扩展符号（本模块对 SwiftUI 类型所做 extension 的成员）：缺失只告警。
#
# 不设为失败判据的原因：这批符号的产出与数量受 Apple 内部模块拆分影响最大——
# 实测同一个 commit，本机（Swift 6.4）产出 17 条、CI（Swift 6.1.2）产出 15 条。
# 把它们计入失败，等于把"Apple 调整了 SwiftUI 的模块组织"变成红灯。
# 真正的删除仍会在 annotation 与日志里留下记录，供人工确认。
comm -23 "$work_dir/baseline-external" "$work_dir/current-external" > "$removed"
if [[ -s "$removed" ]]; then
    note "WARNING: $(count_lines "$removed") cross-module extension symbols in the baseline are absent"
    note "         from this toolchain's symbol graphs. Not treated as a failure (see script comment)."
    head -20 "$removed" | sed 's/^/         /'
    emit_annotation warning "API baseline: external symbols differ" \
"[external symbols absent in this toolchain: $(count_lines "$removed")]
$(head -20 "$removed")
$summary"
fi

if [[ "$failed" -ne 0 ]]; then
    exit 1
fi

emit_annotation notice "API baseline OK" "$summary"
note "Public API compatibility check passed."
