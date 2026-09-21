#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
baseline="$project_dir/Tests/APICompatibility/EasyDesignSystem-PublicAPI.txt"
work_dir="$(mktemp -d -t eds-api-check)"
removed="$work_dir/removed"

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
        echo "symbolgraph inventory + dump tail:"
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

# 逐个文件读，不用 `find | xargs jq`：
# 一旦 find 匹配为空，BSD xargs 会什么都不跑，$current 变空文件，
# 于是整个基线都被报成"已删除"。显式循环可以直接查出这种状态。
current="$work_dir/current"
: > "$current"
while IFS= read -r -d '' graph; do
    jq -r '.symbols[].identifier.precise' "$graph" >> "$current"
done < <(find .build -path "*/symbolgraph/EasyDesignSystem*.symbols.json" ! -name "*Catalog*" -print0)
LC_ALL=C sort -u "$current" -o "$current"

if [[ ! -s "$current" ]]; then
    diagnostics="$(
        echo "no public symbol identifiers were extracted from:"
        graph_dump
    )"
    note "Public API compatibility check failed. No public symbol identifiers were extracted."
    note "$diagnostics"
    emit_annotation error "API baseline: no symbols extracted" "$diagnostics"
    exit 1
fi

# 基线拆分为「本模块符号」与「跨模块扩展符号」两个集合。
#
# 起因：`s:7SwiftUI4ViewP16EasyDesignSystemE04easyE0…` 这类标识符的第一段是
# 被扩展类型所属的**外部**模块。Xcode 16.4 → 27 之间 Apple 把 SwiftUI 拆成
# SwiftUI + SwiftUICore，同一个扩展的 mangled 前缀随之可能变化。业务代码一字
# 未改，却会被判"公开 API 被删"——这是本地与 CI 结论不一致的一个来源。
#
# 对策：对非本模块符号做前缀归一化（`s:<len><外模块名>` → `s:EXTERNAL_`），
# 剩余部分（成员名与签名 mangling）仍严格比对，不放松任何真实差异。
core_prefix="s:16EasyDesignSystem"

normalize_external() {
    sed -E 's/^s:[0-9]+[A-Za-z_]+/s:EXTERNAL_/'
}

baseline_ids="$work_dir/baseline-ids"
grep -v '^[[:space:]]*$' "$baseline" | cut -f1 | LC_ALL=C sort -u > "$baseline_ids"

grep "^$core_prefix"    "$baseline_ids" | LC_ALL=C sort -u > "$work_dir/baseline-core"
grep "^$core_prefix"    "$current"      | LC_ALL=C sort -u > "$work_dir/current-core"
grep -v "^$core_prefix" "$baseline_ids" | normalize_external | LC_ALL=C sort -u > "$work_dir/baseline-external"
grep -v "^$core_prefix" "$current"      | normalize_external | LC_ALL=C sort -u > "$work_dir/current-external"

summary="Baseline symbols: $(count_lines "$baseline_ids") (core $(count_lines "$work_dir/baseline-core") + external $(count_lines "$work_dir/baseline-external")) | current public symbols: $(count_lines "$current") (core $(count_lines "$work_dir/current-core") + external $(count_lines "$work_dir/current-external"))"
note "$summary"

failed=0
failure_report=""

comm -23 "$work_dir/baseline-core" "$work_dir/current-core" > "$removed"
if [[ -s "$removed" ]]; then
    failed=1
    failure_report+="[removed core symbols: $(count_lines "$removed")]"$'\n'
    failure_report+="$(head -30 "$removed")"$'\n'
    note "Public API compatibility check failed. Removed core public symbols ($(count_lines "$removed")):"
    head -50 "$removed"
    if [[ $(count_lines "$removed") -gt 50 ]]; then
        note "  … $(($(count_lines "$removed") - 50)) more omitted"
    fi
fi

if [[ ! -s "$work_dir/current-external" ]]; then
    note "NOTE: this toolchain emitted no external (cross-module extension) symbols;"
    note "      skipping $(count_lines "$work_dir/baseline-external") such baseline entries."
elif comm -23 "$work_dir/baseline-external" "$work_dir/current-external" > "$removed" && [[ -s "$removed" ]]; then
    failed=1
    failure_report+="[removed external symbols: $(count_lines "$removed")]"$'\n'
    failure_report+="$(head -30 "$removed")"$'\n'
    note "Public API compatibility check failed. Removed cross-module extension symbols ($(count_lines "$removed")):"
    head -50 "$removed"
    if [[ $(count_lines "$removed") -gt 50 ]]; then
        note "  … $(($(count_lines "$removed") - 50)) more omitted"
    fi
fi

if [[ "$failed" -ne 0 ]]; then
    emit_annotation error "API baseline failed" "$failure_report
toolchain: $(swift --version 2>&1 | head -1) / $(xcodebuild -version 2>&1 | head -1)
$summary"
    exit 1
fi

emit_annotation notice "API baseline OK" "$summary"
note "Public API compatibility check passed."
