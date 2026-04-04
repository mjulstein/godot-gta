[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / quickstart.md

# Quickstart: Web Browser Play

## 1. Validate the desktop project boots

```sh
HOME=/tmp/godot-home godot --headless --path . --quit-after 1
```

## 2. Export the web build

```sh
mkdir -p build/web
HOME=/tmp/godot-home godot --headless --path . --export-release Web build/web/index.html
```

## 3. Serve the exported files locally

From the repository root:

```sh
cd build/web
python3 -m http.server 8000
```

Then open `http://localhost:8000` in desktop Chrome.

## 4. Run browser validation

Use [web_browser_play.md](../../tests/manual/web_browser_play.md) and verify:

- same playable scene and sandbox loop as desktop
- browser window resize preserves fixed framing
- paused fullscreen button and paused `F` both toggle fullscreen
- external fullscreen exit through `Esc` or browser UI does not break pause state
- browser responsiveness remains close enough to desktop that input feel does not require compensating behavior

## 5. Run desktop regression checks

After browser changes, re-run:

- [us1_playable_core.md](../../tests/manual/us1_playable_core.md)
- desktop portions of [web_browser_play.md](../../tests/manual/web_browser_play.md)

## Notes

- This feature targets desktop Chrome only.
- Browser publish helpers are out of scope for `003-web-browser-play`.
- The custom HTML shell is the default fullscreen path, but gameplay and pause state remain in Godot.
