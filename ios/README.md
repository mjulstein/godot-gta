[root](../README.md) / ios

# iOS Build

Generate the local Xcode project with:

```sh
ios/generate_xcode_project.sh
```

This creates an ignored project at `ios/xcode/`.

## Godot Export Templates

The generator expects the iOS export template zip here:

```text
~/Library/Application Support/Godot/export_templates/4.6.1.stable/ios.zip
```

If that directory is empty, install the Godot 4.6.1 export templates first.

Option 1, from the Godot editor:

1. Open Godot 4.6.1.
2. Go to `Editor` -> `Manage Export Templates`.
3. Install the official templates for `4.6.1.stable`.

Option 2, manual install:

1. Download the `4.6.1.stable` export templates archive from Godot.
2. Extract it.
3. Copy the iOS template zip into:

```text
~/Library/Application Support/Godot/export_templates/4.6.1.stable/ios.zip
```

If your Godot home is somewhere else, run the generator with `GODOT_HOME` set:

```sh
GODOT_HOME=/path/to/home ios/generate_xcode_project.sh
```

## Local Team ID Override

Create one of these ignored files and set your Apple Developer team:

- `ios/ConfigOverride.xcconfig` (recommended, persists across project regeneration)
- `ConfigOverride.xcconfig`
- `ios/xcode/ConfigOverride.xcconfig` (temporary, regenerated)

Contents:

```xcconfig
DEVELOPER_TEAM = YOURTEAMID
```

Optional overrides:

```xcconfig
APP_GROUP_ID = group.no.mju.$(DEVELOPER_TEAM).mju.mju-app-group
BUNDLE_IDENTIFIER = com.example.godot-gta
IOS_DEVICE_ID = YOUR_DEVICE_ID
```

## Open In Xcode

Open:

```text
ios/xcode/GodotGTA.xcodeproj
```

Then select your iPhone and run the `GodotGTA` scheme.

## CLI Build And Deploy

To rebuild the current Godot project, install it on a connected iPhone, and launch it:

1. Regenerate the Xcode project from the latest Godot files:

```sh
ios/generate_xcode_project.sh
```

2. List connected Apple devices and copy your iPhone device ID:

```sh
xcrun xctrace list devices
```

3. Save that device ID in a local override so you do not need to pass it each time:

```xcconfig
IOS_DEVICE_ID = YOUR_DEVICE_ID
```

4. Build, install, and launch using the helper script:

```sh
ios/build_and_deploy.sh
```

5. Or pass the device ID explicitly for a one-off run:

```sh
ios/build_and_deploy.sh YOUR_DEVICE_ID
```

The helper script also accepts shell overrides when needed:

```sh
IOS_DEVICE_ID=YOUR_DEVICE_ID BUNDLE_IDENTIFIER=com.example.godot-gta ios/build_and_deploy.sh
```
