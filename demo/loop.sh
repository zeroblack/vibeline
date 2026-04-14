#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUSLINE="$SCRIPT_DIR/../statusline.sh"

export CCSL_SESSIONS_DIR=/tmp/vibeline-demo-no-sessions
export CCSL_CACHE_DIR=/tmp/vibeline-demo-cache
export CCSL_PLAN=api
rm -rf "$CCSL_CACHE_DIR"
mkdir -p "$CCSL_CACHE_DIR"

stages=(
    "5:0.02:12"
    "28:0.18:17"
    "72:0.42:24"
    "135:0.78:33"
    "210:1.40:41"
    "290:2.10:48"
    "470:3.80:56"
    "620:5.70:64"
    "880:8.20:72"
    "1380:13.50:85"
)

for stage in "${stages[@]}"; do
    IFS=':' read -r mins cost pct <<< "$stage"
    start_ms=$(( ( $(date +%s) - mins * 60 ) * 1000 ))
    echo "$start_ms" > "$CCSL_CACHE_DIR/demo.start"

    clear
    echo
    printf '  '
    printf '{"model":{"display_name":"Opus 4.6"},"context_window":{"used_percentage":%s},"session_id":"demo","session_name":"refactor-auth","workspace":{"current_dir":"%s"},"cost":{"total_cost_usd":%s}}' \
        "$pct" "$PWD" "$cost" | bash "$STATUSLINE"
    echo
    echo
    sleep 1.4
done

clear
