#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
catalog_dir="$project_dir/Examples/PlatformCatalog"
project="EDSPlatformCatalog.xcodeproj"
scheme="EDSPlatformCatalog"

cd "$project_dir"
swift build
swift test

cd "$catalog_dir"
xcodebuild -quiet -project "$project" -scheme "$scheme" -configuration Debug -destination "generic/platform=iOS Simulator" -derivedDataPath /tmp/eds-platform-catalog-ios CODE_SIGNING_ALLOWED=NO build

xcodebuild -quiet -project "$project" -scheme "$scheme" -configuration Debug -destination "generic/platform=iOS Simulator" -derivedDataPath /tmp/eds-platform-catalog-ipad TARGETED_DEVICE_FAMILY=2 CODE_SIGNING_ALLOWED=NO build

xcodebuild -quiet -project "$project" -scheme "$scheme" -configuration Debug -destination "generic/platform=macOS" -derivedDataPath /tmp/eds-platform-catalog-macos CODE_SIGNING_ALLOWED=NO build

xcodebuild -quiet -project "$project" -scheme "$scheme" -configuration Debug -destination "generic/platform=macOS,variant=Mac Catalyst" -derivedDataPath /tmp/eds-platform-catalog-catalyst CODE_SIGNING_ALLOWED=NO build

echo "EasyDesignSystem platform builds passed."
