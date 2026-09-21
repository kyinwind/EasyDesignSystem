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

# ─────────────────────────────────────────────────────────────────────────────
# 诊断通道
# ─────────────────────────────────────────────────────────────────────────────
#
# 本仓库的 job 日志接口需要 admin 权限（`/actions/jobs/{id}/logs` 返回 403），
# 公开可读的只有 annotations。因此所有诊断都必须写进 annotation，否则 CI 红了
# 只能看到一句 "exit code 1"（实际踩过：脚本被 signal 打断时连这句都没有意义）。

diag=""
checkpoint="init"

count_lines() {
    wc -l < "$1" | tr -d ' '
}

graph_dump() {
    find .build -path "*symbolgraph*" -name "*.symbols.json" 2>/dev/null | LC_ALL=C sort
}

note() {
    echo "$1"
    diag+="$1"$'\n'
}

cp_mark() {
    checkpoint="$1"
}

# GitHub Actions 的 workflow command 要求换行转义为 %0A、`%` 转义为 %25（顺序敏感）。
emit_annotation() {
    local level="$1" title="$2" body="$3"
    [[ "${GITHUB_ACTIONS:-}" == "true" ]] || return 0
    local escaped
    escaped="$(printf '%s' "$body" | sed -e 's/%/%25/g' | awk '{printf "%s%%0A", $0}')" || return 0
    echo "::${level} title=${title}::${escaped}"
}

# `cmd | head -1` 在 pipefail 下会因 cmd 的失败而失败（macOS 的 bash 3.2 亦然），
# 因此每个外部命令都要显式兜底，否则工具链怪癖会把脚本自己搞挂。
toolchain_summary() {
    local swift_line xcode_line bash_line
    swift_line="$(swift --version 2>&1 | head -1)" || swift_line="<swift --version failed>"
    xcode_line="$(xcodebuild -version 2>&1 | head -1)" || xcode_line="<xcodebuild -version failed>"
    bash_line="bash ${BASH_VERSION}"
    echo "$swift_line / $xcode_line / $bash_line"
}

# 脚本被 signal 打断（实测 CI 上出现过 exit 134）时也要留下线索：
# 至少要知道死在哪一步、之前输出了什么。
on_exit() {
    local status=$?
    if [[ "$status" -ne 0 ]]; then
        emit_annotation error "API baseline script aborted (exit $status)" \
"aborted at checkpoint: ${checkpoint}
exit status: $status
toolchain: $(toolchain_summary)
output so far:
$(printf '%s' "$diag" | tail -25)" || true
    fi
    return 0
}

trap on_exit EXIT

cp_mark "announce"
emit_annotation notice "API baseline: start" "cwd=$project_dir
toolchain: $(toolchain_summary)"
note "API baseline check starting. $(toolchain_summary)"

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
# 跨模块扩展符号（本模块对 SwiftUI 类型所做 extension 的成员）加 `@` 前缀，
# 与本体符号区分，并与本体构建同一个命名空间。

collect_paths() {
    local pattern="$1" prefix="$2" out="$3"
    : > "$out"
    # 逐个文件读，不用 `find | xargs`：find 匹配为空时 xargs 什么都不跑，
    # 输出会变成空文件，从而把整份基线误报成"已删除"。
    local graph
    while IFS= read -r -d '' graph; do
        # 单个图的解析失败不应让整个脚本崩溃：记录下来、跳过该文件。
        if ! jq -r --arg p "$prefix" '.symbols[]? | .pathComponents | $p + join(".")' "$graph" >> "$out" 2>>"$work_dir/jq-errors.log"; then
            note "WARNING: jq failed on $graph (exit $?); see below"
            tail -5 "$work_dir/jq-errors.log" 2>/dev/null | sed 's/^/  /' || true
        fi
    done < <(find .build -path "$pattern" -print0)
    LC_ALL=C sort -u "$out" -o "$out" || true
}

# Swift 6.1 may return a failure after successfully emitting library symbol
# graphs because it also tries to load SwiftPM's synthetic PackageTests module.
# Clear old graphs first, then accept that known partial failure only when the
# expected graphs were freshly produced.
cp_mark "dump-symbol-graph"
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
cp_mark "assert-symbol-graphs"
core_graph="$(find .build -path "*/symbolgraph/EasyDesignSystem.symbols.json" -print -quit)"
extension_graph="$(find .build -path "*/symbolgraph/EasyDesignSystem@*.symbols.json" -print -quit)"

if [[ -z "$core_graph" || -z "$extension_graph" ]]; then
    note "Public API compatibility check failed. Symbol graphs were not generated."
    note "  core graph (EasyDesignSystem)        : ${core_graph:-<missing>}"
    note "  extension graph (EasyDesignSystem@*) : ${extension_graph:-<missing>}"
    note "  dump-symbol-graph exit status        : $symbol_graph_status"
    note "  symbolgraph inventory:"
    graph_dump | sed 's/^/    /'
    note "  --- dump-symbol-graph output (tail 40) ---"
    printf '%s\n' "$symbol_graph_output" | tail -40
    exit 1
fi

if [[ "$symbol_graph_status" -ne 0 ]]; then
    note "Ignoring SwiftPM's symbol-graph failure for non-library modules; the expected graphs were generated."
fi

cp_mark "collect-paths"
current="$work_dir/current"
collect_paths "*/symbolgraph/EasyDesignSystem.symbols.json"   ""  "$work_dir/current-core"
collect_paths "*/symbolgraph/EasyDesignSystem@*.symbols.json" "@" "$work_dir/current-external"
cat "$work_dir/current-core" "$work_dir/current-external" | LC_ALL=C sort -u > "$current"

if [[ ! -s "$current" ]]; then
    note "Public API compatibility check failed. No public symbol paths were extracted."
    note "  symbolgraph inventory:"
    graph_dump | sed 's/^/    /'
    exit 1
fi

summary="core $(count_lines "$work_dir/current-core") + external $(count_lines "$work_dir/current-external") = $(count_lines "$current") public symbols | $(toolchain_summary)"

if [[ "$update_baseline" -eq 1 ]]; then
    cp_mark "update-baseline"
    {
        echo "# EasyDesignSystem 公开 API 基线"
        echo "#"
        echo "# 判据是**符号路径**（symbolgraph 的 pathComponents 拼接），不是 mangled name。"
        echo "# 原因：mangled name 会把外部模块名编进去（如 7SwiftUI18LocalizedStringKeyV、"
        echo "# 7SwiftUI4ViewRz），而 Apple 在 Xcode 16 → 27 之间把 SwiftUI 拆出了 SwiftUICore，"
        echo "# 同一个 commit 在不同 Xcode 上会算出不同 identifier，产生本地过 CI 挂的假阳性。"
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

cp_mark "read-baseline"
baseline_ids="$work_dir/baseline-ids"
grep -v '^#' "$baseline" 2>/dev/null | grep -v '^[[:space:]]*$' | LC_ALL=C sort -u > "$baseline_ids" || true

if [[ ! -s "$baseline_ids" ]]; then
    note "Public API compatibility check failed. Baseline file is empty or missing: $baseline"
    exit 1
fi

summary="Baseline $(count_lines "$baseline_ids") symbols | current $(count_lines "$current") (core $(count_lines "$work_dir/current-core") + external $(count_lines "$work_dir/current-external")) | $(toolchain_summary)"
note "$summary"

cp_mark "compare-core"
grep -v '^@' "$baseline_ids" > "$work_dir/baseline-core" || true
grep '^@'    "$baseline_ids" > "$work_dir/baseline-external" || true

failed=0

# ① 本体符号：缺失即失败。这是"公开 API 被删"的硬判据。
comm -23 "$work_dir/baseline-core" "$work_dir/current-core" > "$removed" || true
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
comm -23 "$work_dir/baseline-external" "$work_dir/current-external" > "$removed" || true
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

cp_mark "done"
emit_annotation notice "API baseline OK" "$summary"
note "Public API compatibility check passed."
