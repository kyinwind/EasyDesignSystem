#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
catalog_dir="$project_dir/Examples/PlatformCatalog"
device_family="${1:-iPhone}"

case "$device_family" in
    iPhone|iPad) ;;
    *)
        echo "Usage: $0 [iPhone|iPad]"
        exit 2
        ;;
esac

device_id="$(xcrun simctl list devices available -j | jq -r --arg family "$device_family" '[.devices[][] | select(.isAvailable == true and (.name | startswith($family)))] | first | .udid // empty')"

if [[ -z "$device_id" ]]; then
    echo "No available $device_family Simulator was found."
    exit 1
fi

xcodebuild \
    -quiet \
    -project "$catalog_dir/EDSPlatformCatalog.xcodeproj" \
    -scheme EDSPlatformCatalog \
    -destination "platform=iOS Simulator,id=$device_id" \
    -derivedDataPath /tmp/eds-platform-ui-tests \
    CODE_SIGNING_ALLOWED=NO \
    test
