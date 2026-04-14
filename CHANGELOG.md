# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/zeroblack/vibeline/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/zeroblack/vibeline/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/zeroblack/vibeline/releases/tag/v0.1.0
