#!/usr/bin/env bash
set -euo pipefail

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
	echo "Run this script, do not source it:" >&2
	echo "  ios/generate_xcode_project.sh" >&2
	return 1 2>/dev/null || exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$ROOT_DIR/ios/xcode"
APP_DIR="$BUILD_DIR/GodotGTA"
XCODEPROJ_DIR="$BUILD_DIR/GodotGTA.xcodeproj"
SCHEME_DIR="$XCODEPROJ_DIR/xcshareddata/xcschemes"
PACK_PATH="$BUILD_DIR/GodotGTA.pck"
GODOT_HOME_DIR="${GODOT_HOME:-$HOME}"
TEMPLATE_ZIP="$GODOT_HOME_DIR/Library/Application Support/Godot/export_templates/4.6.1.stable/ios.zip"
ICON_PNG="$BUILD_DIR/godot-gta-icon.png"
APPICON_DIR="$APP_DIR/Images.xcassets/godot-gta.appiconset"
CONFIG_ID="A1B2C3D4E5F6012345678901"
MOLTENVK_BUILD_ID="A1B2C3D4E5F6012345678902"
MOLTENVK_FILE_ID="A1B2C3D4E5F6012345678903"

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || {
		echo "Missing required command: $1" >&2
		exit 1
	}
}

replace_all() {
	local file="$1"
	local search="$2"
	local replace="$3"
	SEARCH="$search" REPLACE="$replace" perl -0pi -e 'my $search = $ENV{SEARCH}; my $replace = $ENV{REPLACE}; s/\Q$search\E/$replace/g' "$file"
}

write_info_plist() {
	cat >"$APP_DIR/GodotGTA-Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>$(APP_DISPLAY_NAME)</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIcons</key>
	<dict/>
	<key>CFBundleIcons~ipad</key>
	<dict/>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key>
	<string>$(CURRENT_PROJECT_VERSION)</string>
	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UIRequiredDeviceCapabilities</key>
	<array>
		<string>arm64</string>
	</array>
	<key>UIRequiresFullScreen</key>
	<true/>
	<key>UIStatusBarHidden</key>
	<true/>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UILaunchStoryboardName</key>
	<string>Launch Screen</string>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLName</key>
			<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>$(APP_URL_SCHEME)</string>
			</array>
		</dict>
	</array>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
</dict>
</plist>
EOF
}

write_entitlements() {
	cat >"$APP_DIR/GodotGTA.entitlements" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>$(APP_GROUP_ID)</string>
	</array>
</dict>
</plist>
EOF
}

write_export_options() {
	cat >"$APP_DIR/export_options.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>$(DEVELOPER_TEAM)</string>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF
}

resize_icon() {
	local size="$1"
	local name="$2"
	sips -z "$size" "$size" "$ICON_PNG" --out "$APPICON_DIR/$name" >/dev/null
}

patch_pbxproj() {
	local pbxproj="$XCODEPROJ_DIR/project.pbxproj"
	replace_all "$pbxproj" '$binary' 'GodotGTA'
	replace_all "$pbxproj" '$name' 'GodotGTA'
	replace_all "$pbxproj" '$modules_buildfile' ''
	replace_all "$pbxproj" '$modules_fileref' ''
	replace_all "$pbxproj" '$modules_buildphase' ''
	replace_all "$pbxproj" '$modules_buildgrp' ''
	replace_all "$pbxproj" '$pbx_embeded_frameworks' ''
	replace_all "$pbxproj" '$additional_pbx_frameworks_build' ''
	replace_all "$pbxproj" '$additional_pbx_frameworks_refs' ''
	replace_all "$pbxproj" '$additional_pbx_resources_refs' ''
	replace_all "$pbxproj" '$additional_pbx_resources_build' ''
	replace_all "$pbxproj" '$additional_pbx_files' ''
	replace_all "$pbxproj" '$pbx_locale_file_reference' ''
	replace_all "$pbxproj" '$pbx_locale_build_reference' ''
	replace_all "$pbxproj" '$moltenvk_buildfile' "${MOLTENVK_BUILD_ID} /* MoltenVK.xcframework in Frameworks */ = {isa = PBXBuildFile; fileRef = ${MOLTENVK_FILE_ID} /* MoltenVK.xcframework */; };"
	replace_all "$pbxproj" '$moltenvk_fileref' "${MOLTENVK_FILE_ID} /* MoltenVK.xcframework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.xcframework; path = MoltenVK.xcframework; sourceTree = \"<group>\"; };"
	replace_all "$pbxproj" '$moltenvk_buildphase' "${MOLTENVK_BUILD_ID} /* MoltenVK.xcframework in Frameworks */,"
	replace_all "$pbxproj" '$moltenvk_buildgrp' "${MOLTENVK_FILE_ID} /* MoltenVK.xcframework */,"
	replace_all "$pbxproj" '$pbx_launch_screen_build_reference' ''
	replace_all "$pbxproj" '$pbx_launch_screen_file_reference' ''
	replace_all "$pbxproj" '$pbx_launch_screen_copy_files' ''
	replace_all "$pbxproj" '$pbx_launch_screen_build_phase' ''
	replace_all "$pbxproj" '$team_id' '$(DEVELOPER_TEAM)'
	replace_all "$pbxproj" '$bundle_identifier' '$(BUNDLE_IDENTIFIER)'
	replace_all "$pbxproj" '$short_version' '$(APP_VERSION)'
	replace_all "$pbxproj" '$version' '1'
	replace_all "$pbxproj" '$default_build_config' 'Debug'
	replace_all "$pbxproj" '$code_sign_style_debug' 'Automatic'
	replace_all "$pbxproj" '$code_sign_style_release' 'Automatic'
	replace_all "$pbxproj" '$code_sign_identity_debug' 'Apple Development'
	replace_all "$pbxproj" '$code_sign_identity_release' 'Apple Development'
	replace_all "$pbxproj" '$provisioning_profile_uuid_debug' ''
	replace_all "$pbxproj" '$provisioning_profile_uuid_release' ''
	replace_all "$pbxproj" '$provisioning_profile_specifier_debug' ''
	replace_all "$pbxproj" '$provisioning_profile_specifier_release' ''
	replace_all "$pbxproj" '$sdkroot' 'iphoneos'
	replace_all "$pbxproj" '$targeted_device_family' '1,2'
	replace_all "$pbxproj" '$valid_archs' 'arm64'
	replace_all "$pbxproj" '$godot_archs' 'arm64'
	replace_all "$pbxproj" '$os_deployment_target' 'IPHONEOS_DEPLOYMENT_TARGET = "$(MIN_IOS_VERSION)";'
	replace_all "$pbxproj" '$linker_flags' ''
	replace_all "$pbxproj" 'ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;' 'ASSETCATALOG_COMPILER_APPICON_NAME = "$(APP_ICON)";'
	replace_all "$pbxproj" 'INFOPLIST_KEY_CFBundleDisplayName = "GodotGTA";' 'INFOPLIST_KEY_CFBundleDisplayName = "$(APP_DISPLAY_NAME)";'
	replace_all "$pbxproj" 'MARKETING_VERSION = "$(APP_VERSION)";' 'MARKETING_VERSION = "$(APP_VERSION)";'
	replace_all "$pbxproj" 'DevelopmentTeam = $(DEVELOPER_TEAM);' 'DevelopmentTeam = "$(DEVELOPER_TEAM)";'
	replace_all "$pbxproj" 'DEVELOPMENT_TEAM = $(DEVELOPER_TEAM);' 'DEVELOPMENT_TEAM = "$(DEVELOPER_TEAM)";'
	replace_all "$pbxproj" 'PRODUCT_BUNDLE_IDENTIFIER = $(BUNDLE_IDENTIFIER);' 'PRODUCT_BUNDLE_IDENTIFIER = "$(BUNDLE_IDENTIFIER)";'
	replace_all "$pbxproj" 'MARKETING_VERSION = $(APP_VERSION);' 'MARKETING_VERSION = "$(APP_VERSION)";'

	perl -0pi -e 's@(/\* Begin PBXFileReference section \*/\n)@$1\t\tA1B2C3D4E5F6012345678901 /* Config.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; path = Config.xcconfig; sourceTree = "<group>"; };\n@' "$pbxproj"
	perl -0pi -e 's@(D0BCFE2B18AEBDA2004A7AAE = \{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(\n\t\t\t\t1F1575711F582BE20003B888 /\* dylibs \*/,\n\t\t\t\tD0BCFE7718AEBFEB004A7AAE /\* GodotGTA\.pck \*/,?\n)@$1\t\t\t\tA1B2C3D4E5F6012345678901 /* Config.xcconfig */,\n@' "$pbxproj"
	perl -0pi -e 's@(D0BCFE6F18AEBDA3004A7AAE /\* Debug \*/ = \{\n\t\t\tisa = XCBuildConfiguration;\n)@$1\t\t\tbaseConfigurationReference = A1B2C3D4E5F6012345678901 /* Config.xcconfig */;\n@' "$pbxproj"
	perl -0pi -e 's@(D0BCFE7018AEBDA3004A7AAE /\* Release \*/ = \{\n\t\t\tisa = XCBuildConfiguration;\n)@$1\t\t\tbaseConfigurationReference = A1B2C3D4E5F6012345678901 /* Config.xcconfig */;\n@' "$pbxproj"
	perl -0pi -e 's@(D0BCFE7218AEBDA3004A7AAE /\* Debug \*/ = \{\n\t\t\tisa = XCBuildConfiguration;\n)@$1\t\t\tbaseConfigurationReference = A1B2C3D4E5F6012345678901 /* Config.xcconfig */;\n@' "$pbxproj"
	perl -0pi -e 's@(D0BCFE7318AEBDA3004A7AAE /\* Release \*/ = \{\n\t\t\tisa = XCBuildConfiguration;\n)@$1\t\t\tbaseConfigurationReference = A1B2C3D4E5F6012345678901 /* Config.xcconfig */;\n@' "$pbxproj"
}

patch_workspace_and_scheme() {
	local workspace="$XCODEPROJ_DIR/project.xcworkspace/contents.xcworkspacedata"
	local scheme="$SCHEME_DIR/GodotGTA.xcscheme"
	replace_all "$workspace" '$binary' 'GodotGTA'
	replace_all "$scheme" '$binary' 'GodotGTA'
	replace_all "$scheme" '$default_build_config' 'Debug'
	replace_all "$scheme" 'A340BDFEBCA49239A941883D' 'D0BCFE3318AEBDA2004A7AAE'
	replace_all "$workspace" 'location = "self:GodotGTA.xcodeproj"' 'location = "self:"'
}

patch_template_sources() {
	cat >"$APP_DIR/dummy.cpp" <<'EOF'
/**************************************************************************/
/*  dummy.cpp                                                             */
/**************************************************************************/
/*                         This file is part of:                          */
/*                             GODOT ENGINE                               */
/*                        https://godotengine.org                         */
/**************************************************************************/
/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/

void godot_apple_embedded_plugins_initialize() {}
void godot_apple_embedded_plugins_deinitialize() {}
EOF
	replace_all "$APP_DIR/dummy.swift" '$swift_code' ''
}

require_cmd godot
require_cmd unzip
require_cmd perl
require_cmd sips

if [[ ! -f "$TEMPLATE_ZIP" ]]; then
	echo "Missing iOS export template at:" >&2
	echo "  $TEMPLATE_ZIP" >&2
	echo "Install Godot 4.6.1 export templates first, or rerun with GODOT_HOME pointing at a Godot home that has them." >&2
	exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

HOME="$GODOT_HOME_DIR" godot --headless --path "$ROOT_DIR" --export-pack LinuxPack "$PACK_PATH"
unzip -oq "$TEMPLATE_ZIP" -d "$BUILD_DIR"

mv "$BUILD_DIR/data.pck" "$BUILD_DIR/data.pck.template"
mv "$PACK_PATH" "$BUILD_DIR/GodotGTA.pck"
cp -R "$BUILD_DIR/libgodot.ios.debug.xcframework" "$BUILD_DIR/GodotGTA.xcframework"
mv "$BUILD_DIR/godot_apple_embedded" "$APP_DIR"
mv "$BUILD_DIR/godot_apple_embedded.xcodeproj" "$XCODEPROJ_DIR"
mv "$SCHEME_DIR/godot_apple_embedded.xcscheme" "$SCHEME_DIR/GodotGTA.xcscheme"
mv "$APP_DIR/godot_apple_embedded-Info.plist" "$APP_DIR/GodotGTA-Info.plist"
mv "$APP_DIR/godot_apple_embedded.entitlements" "$APP_DIR/GodotGTA.entitlements"

cp "$ROOT_DIR/ios/Config.xcconfig" "$BUILD_DIR/Config.xcconfig"
write_info_plist
write_entitlements
write_export_options
patch_pbxproj
patch_workspace_and_scheme
patch_template_sources

cp "$ROOT_DIR/ios/base-icon.png" "$ICON_PNG"
mkdir -p "$APPICON_DIR"
cp "$ROOT_DIR/ios/AppIconContents.json" "$APPICON_DIR/Contents.json"
resize_icon 40 iphone-20@2x.png
resize_icon 60 iphone-20@3x.png
resize_icon 58 iphone-29@2x.png
resize_icon 87 iphone-29@3x.png
resize_icon 80 iphone-40@2x.png
resize_icon 120 iphone-40@3x.png
resize_icon 120 iphone-60@2x.png
resize_icon 180 iphone-60@3x.png
resize_icon 20 ipad-20@1x.png
resize_icon 40 ipad-20@2x.png
resize_icon 29 ipad-29@1x.png
resize_icon 58 ipad-29@2x.png
resize_icon 40 ipad-40@1x.png
resize_icon 80 ipad-40@2x.png
resize_icon 76 ipad-76@1x.png
resize_icon 152 ipad-76@2x.png
resize_icon 167 ipad-83.5@2x.png
resize_icon 1024 ios-marketing.png

echo "Generated Xcode project:"
echo "  $XCODEPROJ_DIR"
echo
echo "Create a local override file before signing if needed:"
echo "  $ROOT_DIR/ios/ConfigOverride.xcconfig"
