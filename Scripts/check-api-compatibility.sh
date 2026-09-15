#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
baseline="$project_dir/Tests/APICompatibility/EasyDesignSystem-PublicAPI.txt"
current="$(mktemp -t eds-public-api)"
baseline_identifiers="$(mktemp -t eds-baseline-identifiers)"
removed="$(mktemp -t eds-removed-api)"

cd "$project_dir"

# Swift 6.1 may return a failure after successfully emitting library symbol
# graphs because it also tries to load SwiftPM's synthetic PackageTests module.
# Clear old graphs first, then accept that known partial failure only when the
# EasyDesignSystem graph was freshly produced.
find .build -path "*/symbolgraph/*.symbols.json" -delete 2>/dev/null || true
set +e
symbol_graph_output="$(swift package dump-symbol-graph --pretty-print --skip-synthesized-members --minimum-access-level public 2>&1)"
symbol_graph_status=$?
set -e
echo "$symbol_graph_output"

if ! find .build -path "*/symbolgraph/EasyDesignSystem.symbols.json" -print -quit | grep -q .; then
    echo "Public API compatibility check failed. EasyDesignSystem symbol graph was not generated."
    exit "$symbol_graph_status"
fi

if [[ "$symbol_graph_status" -ne 0 ]]; then
    echo "Ignoring SwiftPM's symbol-graph failure for non-library modules; EasyDesignSystem.symbols.json was generated."
fi

cut -f1 "$baseline" | LC_ALL=C sort -u > "$baseline_identifiers"
find .build -path "*/symbolgraph/EasyDesignSystem*.symbols.json" ! -name "*Catalog*" -print0 | xargs -0 jq -r '.symbols[].identifier.precise' | LC_ALL=C sort -u > "$current"

comm -23 "$baseline_identifiers" "$current" > "$removed"

if [[ -s "$removed" ]]; then
    echo "Public API compatibility check failed. Removed public symbol identifiers:"
    cat "$removed"
    exit 1
fi

echo "Public API compatibility check passed."
