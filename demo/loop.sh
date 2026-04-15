#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUSLINE="$SCRIPT_DIR/../statusline.sh"

export CCSL_SESSIONS_DIR=/tmp/vibeline-demo-no-sessions
export CCSL_CACHE_DIR=/tmp/vibeline-demo-cache
export CCSL_PROJECTS_DIR=/tmp/vibeline-demo-no-projects
export CCSL_PLAN=max20
rm -rf "$CCSL_CACHE_DIR"
mkdir -p "$CCSL_CACHE_DIR"

DEMO_REPO=/tmp/auth-service
rm -rf "$DEMO_REPO"
mkdir -p "$DEMO_REPO"
(
    cd "$DEMO_REPO"
    git init -q -b main
    git config user.email "demo@vibeline.local"
    git config user.name  "demo"
    printf "init\n" > .keep
    git add -A && git commit -q -m "init"
    git checkout -q -b refactor-auth
    printf "x\n" > pending.ts
)

stages=(
    "5:0.02:12:8:6"
    "28:0.18:17:18:14"
    "72:0.42:24:30:22"
    "135:0.78:33:45:35"
    "210:1.40:41:55:44"
    "290:2.10:48:65:52"
    "470:3.80:56:75:60"
    "620:5.70:64:82:68"
    "880:8.20:72:90:75"
    "1380:13.50:85:97:88"
)

for stage in "${stages[@]}"; do
    IFS=':' read -r mins cost pct sess_pct week_pct <<< "$stage"
    start_ms=$(( ( $(date +%s) - mins * 60 ) * 1000 ))
    echo "$start_ms" > "$CCSL_CACHE_DIR/demo.start"

    sess_tokens=$(( 1000000000 * sess_pct / 100 ))
    week_tokens=$(( 6500000000 * week_pct / 100 ))
    echo "$sess_tokens $week_tokens" > "$CCSL_CACHE_DIR/usage"

    clear
    echo
    printf '  '
    printf '{"model":{"display_name":"Opus 4.6"},"context_window":{"used_percentage":%s},"session_id":"demo","session_name":"refactor-auth","workspace":{"current_dir":"%s"},"cost":{"total_cost_usd":%s}}' \
        "$pct" "$DEMO_REPO" "$cost" | bash "$STATUSLINE"
    echo
    echo
    sleep 1.4
done

clear
