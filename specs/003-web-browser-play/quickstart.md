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
- record 10 paused attempts each for fullscreen entry, fullscreen exit, and paused `F` toggle, with at least 9 successes in each set
- external fullscreen exit through `Esc` or browser UI does not break pause state
- gameplay behavior remains on the shared desktop/mobile code path without browser-specific conditionals

## 5. Run desktop regression checks

After browser changes, re-run:

- [us1_playable_core.md](../../tests/manual/us1_playable_core.md)
- desktop portions of [web_browser_play.md](../../tests/manual/web_browser_play.md)

## Notes

- This feature targets desktop Chrome only.
- Browser publish helpers are out of scope for `003-web-browser-play`.
- A custom HTML shell or browser bridge is optional and should be used only if it is the simplest reliable fullscreen path.
