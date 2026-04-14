# Regenerating the demo assets

The hero animation and preview image in the root `README.md` are produced from this directory.

**Prerequisites:**

```bash
brew install vhs ttyd ffmpeg
```

**Rebuild the GIF:**

```bash
# from the repo root
vhs demo/demo.tape
```

Output: `screenshots/demo.gif`.

**Rebuild the static preview (PNG):**

```bash
ffmpeg -i screenshots/demo.gif -vf "select=eq(n\,40)" -vframes 1 screenshots/preview.png -y
```

Frame 40 lands around the ☕ warmed-up stage — adjust if you want a different mood.

## How it works

`loop.sh` renders the statusline ten times with progressively older fake
session start times, cycling through every stage of the elapsed emoji
progression. `demo.tape` wraps that loop in a VHS recording.
