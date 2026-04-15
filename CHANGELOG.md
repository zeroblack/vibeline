# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-04-14

### Added
- Plan usage segment: `🌀 ●●○○○ ~53%` for the current 5h session and `🌓 ●●○○○ ~51%w` for the week. Bars evolve through a wave (🌊→🌀→🌪→⛈️) and moon phase (🌑→🌒→🌓→🌔→🌕) progression. Uses local JSONL aggregation with a 60s async cache so the statusline stays fast.
- `CCSL_SHOW_USAGE`, `CCSL_SESSION_QUOTA_TOKENS`, `CCSL_WEEK_QUOTA_TOKENS`, `CCSL_USAGE_TTL`, `CCSL_PROJECTS_DIR` env vars.
- `CCSL_PLAN=max20` for Max 20x calibration defaults.

### Changed
- All three progress bars (session, week, context) now render as 5-dot `●○` for a lighter visual footprint.
- Line 2 is grouped by domain — code · time (elapsed + clock) · cost · capacity (session + week + context) — so the clock no longer sits isolated after the usage bars.

### Fixed
- Context bar rendered extra blocks at 100% on macOS (BSD `seq` descends when start > end). Both bars now use a while-loop counter.

## [0.2.1] - 2026-04-15

### Fixed
- Shellcheck SC2034 warning in the context-bar rendering loops (`i appears unused`). Loop counter renamed to `_` so CI stays green on newer shellcheck releases.

## [0.2.0] - 2026-04-14

### Changed
- Two-line statusline layout. Identity (model · location · session) sits on line 1; metrics (todos · elapsed · cost · context · clock) on line 2. Long session names no longer truncate the right side of the bar.

## [0.1.1] - 2026-04-14

### Fixed
- Installer hang when piped through `curl | bash` — `exec < /dev/tty` was redirecting bash's script stdin; each `read` now uses `< /dev/tty` locally

## [0.1.0] - 2026-04-13

### Added
- Semantic model icons (🧠 Opus · 🎵 Sonnet · 🍃 Haiku)
- Location block: folder + git branch, dirty count, ahead/behind
- TODO radar with 60s cache
- Session name segment
- 14-stage elapsed time emoji progression spanning 24h
- Cost meter with color tiers
- Activity flash ⚡ on cost delta
- Context usage bar
- Time-of-day clock
- `CCSL_PLAN` for Max/Pro cost prefix
- Env var toggles for every segment
- Interactive installer with settings.json auto-update

[Unreleased]: https://github.com/zeroblack/vibeline/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/zeroblack/vibeline/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/zeroblack/vibeline/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/zeroblack/vibeline/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/zeroblack/vibeline/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/zeroblack/vibeline/releases/tag/v0.1.0
