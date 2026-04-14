# Contributing

Thanks for considering a contribution.

## Ground rules

- **One change per PR.** A bug fix and a new feature belong in separate PRs.
- **Keep the footprint small.** vibeline is intentionally under 300 lines of bash. New segments should pull their weight.
- **Backwards compatible by default.** Existing env var names and defaults should keep working.
- **Emoji are vocabulary, not decoration.** Before adding a new emoji to the script, make sure it communicates its segment's *category*, not just prettifies it.

## Development

```bash
git clone https://github.com/zeroblack/vibeline.git
cd vibeline
shellcheck statusline.sh install.sh
```

To test a render locally without running Claude Code:

```bash
echo '{"model":{"display_name":"Opus 4.6"},"context_window":{"used_percentage":42},"workspace":{"current_dir":"'"$PWD"'"}}' | bash statusline.sh
echo
```

## Commit style

Conventional Commits. Common prefixes:

- `feat:` new segment, new env var, user-facing behavior
- `fix:` bug fix
- `refactor:` no behavior change
- `docs:` README / CHANGELOG / comments
- `ci:` workflows
- `chore:` anything else

One line, imperative, under 72 characters. A body is optional but welcome when the *why* isn't obvious from the diff.

## Releases

Tagged from `main` using [Semantic Versioning](https://semver.org/). The `CHANGELOG.md` is updated in the same commit as the tag.
