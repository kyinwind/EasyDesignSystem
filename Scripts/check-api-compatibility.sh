#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
baseline="$project_dir/Tests/APICompatibility/EasyDesignSystem-PublicAPI.txt"
current="$(mktemp -t eds-public-api)"
baseline_identifiers="$(mktemp -t eds-baseline-identifiers)"
removed="$(mktemp -t eds-removed-api)"

cd "$project_dir"
swift package dump-symbol-graph --pretty-print --skip-synthesized-members --minimum-access-level public

cut -f1 "$baseline" | LC_ALL=C sort -u > "$baseline_identifiers"
find .build -path "*/symbolgraph/EasyDesignSystem*.symbols.json" ! -name "*Catalog*" -print0 | xargs -0 jq -r '.symbols[].identifier.precise' | LC_ALL=C sort -u > "$current"

comm -23 "$baseline_identifiers" "$current" > "$removed"

if [[ -s "$removed" ]]; then
    echo "Public API compatibility check failed. Removed public symbol identifiers:"
    cat "$removed"
    exit 1
fi

echo "Public API compatibility check passed."
