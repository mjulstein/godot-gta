[root](../README.md) / ios

# iOS Build

Generate the local Xcode project with:

```sh
ios/generate_xcode_project.sh
```

This creates an ignored project at `ios/build/GodotGTA/`.

## Local Team ID Override

Create one of these ignored files and set your Apple Developer team:

- `ios/ConfigOverride.xcconfig` (recommended, persists across project regeneration)
- `ConfigOverride.xcconfig`
- `ios/build/GodotGTA/ConfigOverride.xcconfig` (temporary, regenerated)

Contents:

```xcconfig
DEVELOPER_TEAM = YOURTEAMID
```

Optional overrides:

```xcconfig
APP_GROUP_ID = group.no.mju.$(DEVELOPER_TEAM).mju.mju-app-group
```

## Open In Xcode

Open:

```text
ios/build/GodotGTA/GodotGTA.xcodeproj
```

Then select your iPhone and run the `GodotGTA` scheme.
