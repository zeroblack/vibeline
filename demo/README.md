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
ffmpeg -i screenshots/demo.gif -vf "select=eq(n\,220)" -vframes 1 -update 1 screenshots/preview.png -y
```

Frame 220 lands around the 💪 bionic stage with the usage bars mid-progression — adjust if you want a different mood.

## How it works

`loop.sh` spins up a throwaway git repo at `/tmp/auth-service`, then renders the statusline ten times with progressively older fake session start times, cycling through every stage of the elapsed emoji progression and the usage bars. `demo.tape` wraps that loop in a VHS recording.
