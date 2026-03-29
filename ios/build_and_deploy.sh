#!/usr/bin/env bash
set -euo pipefail

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
	echo "Run this script, do not source it:" >&2
	echo "  ios/build_and_deploy.sh [DEVICE_ID]" >&2
	return 1 2>/dev/null || exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/godot-gta-derived}"
PROJECT_PATH="$ROOT_DIR/ios/xcode/GodotGTA.xcodeproj"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphoneos/GodotGTA.app"
ALLOW_PROVISIONING_UPDATES="${ALLOW_PROVISIONING_UPDATES:-1}"

CONFIG_FILES=(
	"$ROOT_DIR/ios/xcode/ConfigOverride.xcconfig"
	"$ROOT_DIR/ios/ConfigOverride.xcconfig"
	"$ROOT_DIR/ConfigOverride.xcconfig"
	"$ROOT_DIR/ios/Config.xcconfig"
)

trim() {
	local value="$1"
	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"
	printf '%s' "$value"
}

resolve_config_value() {
	local key="$1"
	local file
	for file in "${CONFIG_FILES[@]}"; do
		if [[ ! -f "$file" ]]; then
			continue
		fi
		while IFS= read -r raw_line; do
			local line
			line="$(trim "$raw_line")"
			[[ -z "$line" ]] && continue
			[[ "$line" == //* ]] && continue
			[[ "$line" != "$key"* ]] && continue
			[[ "$line" != *=* ]] && continue
			line="${line#*=}"
			line="${line%%//*}"
			line="$(trim "$line")"
			line="${line%;}"
			line="$(trim "$line")"
			line="${line#\"}"
			line="${line%\"}"
			printf '%s' "$line"
			return 0
		done < "$file"
	done
	return 1
}

expand_xcconfig_vars() {
	local value="$1"
	local developer_team="${DEVELOPER_TEAM_VALUE:-}"
	local development_team="${DEVELOPMENT_TEAM_VALUE:-}"
	value="${value//\$\(DEVELOPER_TEAM\)/$developer_team}"
	value="${value//\$\(DEVELOPMENT_TEAM\)/$development_team}"
	printf '%s' "$value"
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || {
		echo "Missing required command: $1" >&2
		exit 1
	}
}

require_cmd xcodebuild
require_cmd xcrun

DEVICE_ID="${1:-}"
if [[ -z "$DEVICE_ID" ]]; then
	DEVICE_ID="${IOS_DEVICE_ID:-}"
fi
if [[ -z "$DEVICE_ID" ]]; then
	DEVICE_ID="$(resolve_config_value "IOS_DEVICE_ID" || true)"
fi
if [[ -z "$DEVICE_ID" ]]; then
	echo "Missing device ID." >&2
	echo "Pass it as the first argument or set IOS_DEVICE_ID in a local ConfigOverride.xcconfig file." >&2
	exit 1
fi

BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-}"
if [[ -z "$BUNDLE_IDENTIFIER" ]]; then
	BUNDLE_IDENTIFIER="$(resolve_config_value "BUNDLE_IDENTIFIER" || true)"
fi
if [[ -z "$BUNDLE_IDENTIFIER" ]]; then
	echo "Missing BUNDLE_IDENTIFIER in xcconfig." >&2
	echo "Set it in one of these files or export BUNDLE_IDENTIFIER in your shell:" >&2
	for file in "${CONFIG_FILES[@]}"; do
		echo "  $file" >&2
	done
	exit 1
fi

DEVELOPER_TEAM_VALUE="${DEVELOPER_TEAM:-$(resolve_config_value "DEVELOPER_TEAM" || true)}"
DEVELOPMENT_TEAM_VALUE="${DEVELOPMENT_TEAM:-$(resolve_config_value "DEVELOPMENT_TEAM" || true)}"
if [[ -z "$DEVELOPMENT_TEAM_VALUE" ]]; then
	DEVELOPMENT_TEAM_VALUE="$DEVELOPER_TEAM_VALUE"
fi

BUNDLE_IDENTIFIER="$(expand_xcconfig_vars "$BUNDLE_IDENTIFIER")"

cd "$ROOT_DIR"

ios/generate_xcode_project.sh

if [[ ! -d "$PROJECT_PATH" ]]; then
	echo "Generated Xcode project is missing:" >&2
	echo "  $PROJECT_PATH" >&2
	exit 1
fi

XCODEBUILD_ARGS=(
	-project "$PROJECT_PATH"
	-scheme GodotGTA
	-configuration Debug
	-destination "id=$DEVICE_ID"
	-derivedDataPath "$DERIVED_DATA_PATH"
	build
)

if [[ "$ALLOW_PROVISIONING_UPDATES" == "1" ]]; then
	XCODEBUILD_ARGS=(-allowProvisioningUpdates "${XCODEBUILD_ARGS[@]}")
fi

xcodebuild "${XCODEBUILD_ARGS[@]}"

if [[ ! -d "$APP_PATH" ]]; then
	echo "Built app bundle is missing:" >&2
	echo "  $APP_PATH" >&2
	exit 1
fi

xcrun devicectl device install app \
	--device "$DEVICE_ID" \
	"$APP_PATH"

xcrun devicectl device process launch \
	--device "$DEVICE_ID" \
	"$BUNDLE_IDENTIFIER"
