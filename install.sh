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

  On a Claude subscription? Prepend the matching CCSL_PLAN. Examples:
      pro     → Pro               "command": "CCSL_PLAN=pro /bin/bash $TARGET"
      max5    → Max 5x  (\$100/mo) "command": "CCSL_PLAN=max5 /bin/bash $TARGET"
      max20   → Max 20x (\$200/mo) "command": "CCSL_PLAN=max20 /bin/bash $TARGET"
EOF

if [ -f "$SETTINGS" ] && [ -r /dev/tty ]; then
    echo
    read -r -p "Update $SETTINGS automatically? [y/N] " reply < /dev/tty
    if [ "${reply:-N}" = "y" ] || [ "${reply:-N}" = "Y" ]; then
        echo
        echo "Which Claude plan are you on?"
        echo "  1) api    — pay per token (default)"
        echo "  2) pro    — \$20/mo"
        echo "  3) max5   — Max 5x (\$100/mo)"
        echo "  4) max20  — Max 20x (\$200/mo)"
        read -r -p "Choose [1-4] or type the name [1]: " plan_in < /dev/tty
        case "${plan_in:-1}" in
            1|api)     plan="api"   ;;
            2|pro)     plan="pro"   ;;
            3|max5|max) plan="max5" ;;
            4|max20)   plan="max20" ;;
            *)         plan="$plan_in" ;;
        esac
        cmd="/bin/bash $TARGET"
        [ "$plan" != "api" ] && cmd="CCSL_PLAN=$plan $cmd"
        tmp=$(mktemp)
        jq --arg c "$cmd" '.statusLine = {"type":"command","command":$c}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
        echo "✓ $SETTINGS updated (plan: $plan)"
    else
        echo "skipped — update it manually"
    fi
elif [ -f "$SETTINGS" ]; then
    echo
    echo "non-interactive shell — update $SETTINGS manually with the snippet above"
fi

echo
echo "done. restart Claude Code to see the new statusline."
