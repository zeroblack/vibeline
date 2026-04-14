#!/usr/bin/env bash
set -eu

REPO_RAW="${VIBELINE_REPO:-https://raw.githubusercontent.com/zeroblack/vibeline/main}"
TARGET="${VIBELINE_TARGET:-$HOME/.claude/statusline.sh}"
SETTINGS="${VIBELINE_SETTINGS:-$HOME/.claude/settings.json}"

need() {
    command -v "$1" >/dev/null 2>&1 || { echo "missing dependency: $1"; exit 1; }
}

need bash
need jq
need awk
need curl

mkdir -p "$(dirname "$TARGET")"

echo "→ downloading statusline.sh to $TARGET"
curl -fsSL "$REPO_RAW/statusline.sh" -o "$TARGET"
chmod +x "$TARGET"

echo
echo "→ next step: register it in $SETTINGS"
echo
cat <<EOF
  {
    "statusLine": {
      "type": "command",
      "command": "/bin/bash $TARGET"
    }
  }

  If you're on Claude Max or Pro, prepend CCSL_PLAN=max to the command:
      "command": "CCSL_PLAN=max /bin/bash $TARGET"
EOF

if [ -f "$SETTINGS" ] && { [ -t 0 ] || [ -c /dev/tty ]; }; then
    exec < /dev/tty
    echo
    read -r -p "Update $SETTINGS automatically? [y/N] " reply
    if [ "${reply:-N}" = "y" ] || [ "${reply:-N}" = "Y" ]; then
        read -r -p "Plan (api / max / pro) [api]: " plan
        plan="${plan:-api}"
        cmd="/bin/bash $TARGET"
        [ "$plan" != "api" ] && cmd="CCSL_PLAN=$plan $cmd"
        tmp=$(mktemp)
        jq --arg c "$cmd" '.statusLine = {"type":"command","command":$c}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
        echo "✓ $SETTINGS updated"
    else
        echo "skipped — update it manually"
    fi
elif [ -f "$SETTINGS" ]; then
    echo
    echo "non-interactive shell — update $SETTINGS manually with the snippet above"
fi

echo
echo "done. restart Claude Code to see the new statusline."
