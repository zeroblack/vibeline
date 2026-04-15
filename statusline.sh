#!/usr/bin/env bash

: "${CCSL_SHOW_COST:=1}"
: "${CCSL_SHOW_ACTIVITY:=1}"
: "${CCSL_SHOW_TODOS:=1}"
: "${CCSL_SHOW_SESSION_NAME:=1}"
: "${CCSL_SHOW_ELAPSED:=1}"
: "${CCSL_SHOW_CONTEXT:=1}"
: "${CCSL_SHOW_CLOCK:=1}"
: "${CCSL_SHOW_USAGE:=1}"
: "${CCSL_PLAN:=api}"
: "${CCSL_TODO_PATTERN:=\\b(TODO|FIXME|XXX|HACK)\\b}"
: "${CCSL_TODO_TTL:=60}"
: "${CCSL_TASK_TTL:=15}"
: "${CCSL_USAGE_TTL:=60}"
: "${CCSL_ACTIVITY_LINGER:=3}"
: "${CCSL_CACHE_DIR:=$HOME/.claude/cache/statusline}"
: "${CCSL_SESSIONS_DIR:=$HOME/.claude/sessions}"
: "${CCSL_PROJECTS_DIR:=$HOME/.claude/projects}"
: "${CCSL_SESSION_QUOTA_TOKENS:=}"
: "${CCSL_WEEK_QUOTA_TOKENS:=}"

command -v jq  >/dev/null 2>&1 || { printf "statusline: jq required\n";  exit 0; }
command -v awk >/dev/null 2>&1 || { printf "statusline: awk required\n"; exit 0; }

mkdir -p "$CCSL_CACHE_DIR" 2>/dev/null

C_DIM="\033[2m"; C_RESET="\033[0m"
C_CYAN="\033[96m"
C_BLUE="\033[94m";  C_MAGENTA="\033[95m"
C_YELLOW="\033[93m"; C_ORANGE="\033[33m"; C_MUTED="\033[36m"
C_GREEN="\033[92m";  C_RED="\033[91m";    C_GREY="\033[90m"

stat_mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }
gt() { awk -v a="$1" -v b="$2" 'BEGIN {exit !(a > b)}'; }
ge() { awk -v a="$1" -v b="$2" 'BEGIN {exit !(a >= b)}'; }

input=$(cat)
j() { echo "$input" | jq -r "$1 // empty"; }

model=$(j '.model.display_name'); [ -z "$model" ] && model="Claude"
used_pct=$(j '.context_window.used_percentage')
session_name=$(j '.session_name')
session_id=$(j '.session_id')
cwd=$(j '.workspace.current_dir')
cost_usd=$(j '.cost.total_cost_usd')

session_key="${session_id:-$(echo "$cwd" | tr '/' '_')}"

resolve_session_start() {
    local sid="$1" f s
    if [ -n "$sid" ] && [ -d "$CCSL_SESSIONS_DIR" ]; then
        for f in "$CCSL_SESSIONS_DIR"/*.json; do
            [ -f "$f" ] || continue
            s=$(jq -r '.sessionId // empty' "$f" 2>/dev/null)
            if [ "$s" = "$sid" ]; then
                jq -r '.startedAt // empty' "$f" 2>/dev/null
                return
            fi
        done
    fi
    local start_file="$CCSL_CACHE_DIR/${session_key}.start"
    if [ -f "$start_file" ]; then
        cat "$start_file"
    else
        local now_ms=$(( $(date +%s) * 1000 ))
        echo "$now_ms" > "$start_file"
        echo "$now_ms"
    fi
}

session_start=$(resolve_session_start "$session_id")

elapsed_str=""; time_icon="🌱"
if [ -n "$session_start" ]; then
    elapsed_s=$(( ( $(date +%s) * 1000 - session_start ) / 1000 ))
    [ "$elapsed_s" -lt 0 ] && elapsed_s=0
    mins=$(( elapsed_s / 60 ))
    hours=$(( mins / 60 ))
    if [ "$hours" -gt 0 ]; then
        elapsed_str="${hours}h$(( mins % 60 ))m"
    else
        elapsed_str="${mins}m"
    fi
    if   [ "$mins"  -lt 15 ];  then time_icon="🌱"
    elif [ "$mins"  -lt 45 ];  then time_icon="☕"
    elif [ "$mins"  -lt 90 ];  then time_icon="🔥"
    elif [ "$hours" -lt 3 ];   then time_icon="🚀"
    elif [ "$hours" -lt 4 ];   then time_icon="⚡"
    elif [ "$hours" -lt 5 ];   then time_icon="💪"
    elif [ "$hours" -lt 6 ];   then time_icon="🦾"
    elif [ "$hours" -lt 8 ];   then time_icon="🌋"
    elif [ "$hours" -lt 10 ];  then time_icon="🧙"
    elif [ "$hours" -lt 12 ];  then time_icon="🦉"
    elif [ "$hours" -lt 16 ];  then time_icon="🧟"
    elif [ "$hours" -lt 20 ];  then time_icon="💀"
    elif [ "$hours" -lt 24 ];  then time_icon="☠️"
    else                            time_icon="👻"
    fi
fi

model_icon="🤖"
case "$(echo "$model" | tr '[:upper:]' '[:lower:]')" in
    *opus*)   model_icon="🧠" ;;
    *sonnet*) model_icon="🎵" ;;
    *haiku*)  model_icon="🍃" ;;
esac

folder=""; folder_icon="📁"
if [ -n "$cwd" ]; then
    if [ "$cwd" = "$HOME" ]; then
        folder="~"; folder_icon="🏠"
    else
        folder=$(basename "$cwd")
    fi
fi

git_branch=""; git_status=""; git_ahead_behind=""; git_icon="🌿"; is_git_repo=0
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    is_git_repo=1
    git_branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    if [ -z "$git_branch" ]; then
        git_branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
        git_icon="🔀"
    fi
    dirty=$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    [ "$dirty" -gt 0 ] && git_status=" ✎${dirty}"
    upstream='HEAD...@{u}'
    ab=$(git -C "$cwd" rev-list --left-right --count "$upstream" 2>/dev/null)
    if [ -n "$ab" ]; then
        ahead=$(echo  "$ab" | awk '{print $1}')
        behind=$(echo "$ab" | awk '{print $2}')
        [ "$ahead"  -gt 0 ] && git_ahead_behind="${git_ahead_behind} ↑${ahead}"
        [ "$behind" -gt 0 ] && git_ahead_behind="${git_ahead_behind} ↓${behind}"
    fi
fi

compute_session_tasks() {
    local sid="$1" jsonl
    [ -z "$sid" ] && return
    jsonl=$(find "$CCSL_PROJECTS_DIR" -name "${sid}.jsonl" -print -quit 2>/dev/null)
    [ -z "$jsonl" ] || [ ! -f "$jsonl" ] && return
    jq -rs '
        [.[] | select(.message.content? | type == "array")
             | .message.content[]
             | select(.type == "tool_use" and .name == "TodoWrite")
             | .input.todos] | last
        | if . then
            "\([.[] | select(.status == "completed")] | length) \([.[] | select(.status == "in_progress")] | length) \([.[] | select(.status == "pending")] | length)"
          else empty end
    ' "$jsonl" 2>/dev/null
}

read_session_tasks_cached() {
    local sid="$1" cache age
    cache="$CCSL_CACHE_DIR/tasks-${sid}"
    age=99999
    [ -f "$cache" ] && age=$(( $(date +%s) - $(stat_mtime "$cache") ))
    if [ "$age" -gt "$CCSL_TASK_TTL" ]; then
        if compute_session_tasks "$sid" > "$cache.tmp" 2>/dev/null; then
            mv "$cache.tmp" "$cache"
        else
            rm -f "$cache.tmp"
        fi
    fi
    cat "$cache" 2>/dev/null
}

session_task_line=""
todo_count=""
if [ "$CCSL_SHOW_TODOS" = "1" ]; then
    [ -n "$session_id" ] && session_task_line=$(read_session_tasks_cached "$session_id")
fi
if [ "$CCSL_SHOW_TODOS" = "1" ] && [ -z "$session_task_line" ] && [ "$is_git_repo" = "1" ]; then
    todo_file="$CCSL_CACHE_DIR/$(echo "$cwd" | tr '/' '_').todos"
    stale=1
    if [ -f "$todo_file" ]; then
        age=$(( $(date +%s) - $(stat_mtime "$todo_file") ))
        [ "$age" -lt "$CCSL_TODO_TTL" ] && stale=0
    fi
    if [ "$stale" = "1" ]; then
        c=$(git -C "$cwd" grep -I -c -E "$CCSL_TODO_PATTERN" -- \
                ':(exclude)*.md' ':(exclude)*.markdown' ':(exclude)*.txt' \
                ':(exclude)*.rst'  ':(exclude)CHANGELOG*' ':(exclude)CONTRIBUTING*' \
                2>/dev/null \
            | awk -F: '{sum += $NF} END {print sum+0}')
        echo "${c:-0}" > "$todo_file"
    fi
    todo_count=$(cat "$todo_file" 2>/dev/null)
    [ "$todo_count" = "0" ] && todo_count=""
fi

activity=""
if [ "$CCSL_SHOW_ACTIVITY" = "1" ] && [ -n "$cost_usd" ]; then
    cost_file="$CCSL_CACHE_DIR/${session_key}.cost"
    flash_file="$CCSL_CACHE_DIR/${session_key}.flash"
    prev="0"; [ -f "$cost_file" ] && prev=$(cat "$cost_file")
    echo "$cost_usd" > "$cost_file"
    gt "$cost_usd" "$prev" && date +%s > "$flash_file"
    if [ -f "$flash_file" ]; then
        flash_age=$(( $(date +%s) - $(cat "$flash_file") ))
        [ "$flash_age" -le "$CCSL_ACTIVITY_LINGER" ] && activity="⚡"
    fi
fi

cost_segment=""
if [ "$CCSL_SHOW_COST" = "1" ] && [ -n "$cost_usd" ]; then
    cost_fmt=$(awk -v c="$cost_usd" 'BEGIN {printf "%.2f", c}')
    cost_color="$C_GREEN"
    ge "$cost_usd" 1  && cost_color="$C_YELLOW"
    ge "$cost_usd" 5  && cost_color="$C_ORANGE"
    ge "$cost_usd" 10 && cost_color="$C_RED"
    prefix=""
    case "$(echo "$CCSL_PLAN" | tr '[:upper:]' '[:lower:]')" in
        max|pro) prefix="~" ;;
    esac
    cost_segment="💰  ${cost_color}${prefix}\$${cost_fmt}${C_RESET}"
    [ -n "$activity" ] && cost_segment="${cost_segment} ${C_YELLOW}${activity}${C_RESET}"
fi

plan_lc=$(echo "$CCSL_PLAN" | tr '[:upper:]' '[:lower:]')
case "$plan_lc" in
    pro)   default_session_q=50000000;   default_week_q=325000000 ;;
    max)   default_session_q=250000000;  default_week_q=1625000000 ;;
    max20) default_session_q=1000000000; default_week_q=6500000000 ;;
    *)     default_session_q=0;          default_week_q=0 ;;
esac
session_quota=${CCSL_SESSION_QUOTA_TOKENS:-$default_session_q}
week_quota=${CCSL_WEEK_QUOTA_TOKENS:-$default_week_q}

compute_usage() {
    local session_cutoff week_cutoff files
    session_cutoff=$(date -u -v-5H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
                 || date -u -d '5 hours ago' '+%Y-%m-%dT%H:%M:%SZ')
    week_cutoff=$(date -u -v-7d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
               || date -u -d '7 days ago' '+%Y-%m-%dT%H:%M:%SZ')
    files=$(find "$CCSL_PROJECTS_DIR" -name '*.jsonl' -mmin -10080 2>/dev/null)
    [ -z "$files" ] && { echo "0 0"; return; }
    # shellcheck disable=SC2016
    echo "$files" | tr '\n' '\0' | xargs -0 jq -rs \
        --arg sc "$session_cutoff" --arg wc "$week_cutoff" '
        reduce .[] as $e ({s:0, w:0};
          ($e.message.usage // null) as $u |
          if $u == null or ($e.timestamp // null) == null then .
          else
            (($u.input_tokens // 0) + ($u.output_tokens // 0) +
             ($u.cache_creation_input_tokens // 0) +
             ($u.cache_read_input_tokens // 0)) as $t |
            (if $e.timestamp > $wc then .w += $t else . end) |
            (if $e.timestamp > $sc then .s += $t else . end)
          end
        ) | "\(.s) \(.w)"
    ' 2>/dev/null || echo "0 0"
}

read_usage_cached() {
    local cache="$CCSL_CACHE_DIR/usage"
    local lock="$CCSL_CACHE_DIR/usage.lock"
    local age=99999
    [ -f "$cache" ] && age=$(( $(date +%s) - $(stat_mtime "$cache") ))
    if [ "$age" -gt "$CCSL_USAGE_TTL" ] && [ ! -f "$lock" ]; then
        (
            trap 'rm -f "$lock" "$cache.tmp"' EXIT
            touch "$lock"
            compute_usage > "$cache.tmp" && mv "$cache.tmp" "$cache"
        ) </dev/null >/dev/null 2>&1 &
    fi
    cat "$cache" 2>/dev/null || echo "0 0"
}

session_emoji_for() {
    local p=$1
    if   [ "$p" -ge 90 ]; then echo "⛈️"
    elif [ "$p" -ge 75 ]; then echo "🌪"
    elif [ "$p" -ge 50 ]; then echo "🌀"
    else                       echo "🌊"
    fi
}

week_emoji_for() {
    local p=$1
    if   [ "$p" -ge 90 ]; then echo "🌕"
    elif [ "$p" -ge 75 ]; then echo "🌔"
    elif [ "$p" -ge 50 ]; then echo "🌓"
    elif [ "$p" -ge 25 ]; then echo "🌒"
    else                       echo "🌑"
    fi
}

render_mini_bar() {
    local p=$1 color bar blocks i=0
    blocks=$(( p / 20 ))
    [ "$blocks" -gt 5 ] && blocks=5
    if   [ "$p" -ge 90 ]; then color="$C_RED"
    elif [ "$p" -ge 75 ]; then color="$C_ORANGE"
    elif [ "$p" -ge 50 ]; then color="$C_YELLOW"
    else                       color="$C_GREEN"
    fi
    bar=""
    while [ "$i" -lt "$blocks" ]; do bar="${bar}●"; i=$((i+1)); done
    while [ "$i" -lt 5 ];         do bar="${bar}○"; i=$((i+1)); done
    printf "%b%s%b" "$color" "$bar" "$C_RESET"
}

session_usage_segment=""
week_usage_segment=""
if [ "$CCSL_SHOW_USAGE" = "1" ] && [ "$session_quota" -gt 0 ] && [ "$week_quota" -gt 0 ]; then
    usage_raw=$(read_usage_cached)
    session_tokens=$(echo "$usage_raw" | awk '{print $1+0}')
    week_tokens=$(echo "$usage_raw"   | awk '{print $2+0}')
    session_pct=$(awk -v t="$session_tokens" -v q="$session_quota" \
        'BEGIN { p=(t/q)*100; if (p>100) p=100; printf "%d", p }')
    week_pct=$(awk -v t="$week_tokens" -v q="$week_quota" \
        'BEGIN { p=(t/q)*100; if (p>100) p=100; printf "%d", p }')
    s_bar=$(render_mini_bar "$session_pct")
    w_bar=$(render_mini_bar "$week_pct")
    s_emoji=$(session_emoji_for "$session_pct")
    w_emoji=$(week_emoji_for   "$week_pct")
    session_usage_segment="${s_emoji}  ${s_bar} ${C_DIM}~${session_pct}%${C_RESET}"
    week_usage_segment="${w_emoji}  ${w_bar} ${C_DIM}~${week_pct}%w${C_RESET}"
fi

progress_bar=""; ctx_icon="🧩"
if [ "$CCSL_SHOW_CONTEXT" = "1" ] && [ -n "$used_pct" ]; then
    pct=$(printf "%.0f" "$used_pct")
    blocks=$(( pct / 20 ))
    [ "$blocks" -gt 5 ] && blocks=5
    if   [ "$pct" -ge 80 ]; then bar_color="$C_RED";    ctx_icon="🔴"
    elif [ "$pct" -ge 60 ]; then bar_color="$C_YELLOW"; ctx_icon="🟡"
    else                         bar_color="$C_GREEN";  ctx_icon="🟢"
    fi
    bar=""; i=0
    while [ "$i" -lt "$blocks" ]; do bar="${bar}●"; i=$((i+1)); done
    while [ "$i" -lt 5 ];         do bar="${bar}○"; i=$((i+1)); done
    progress_bar="${bar_color}${bar}${C_RESET} $(printf "%3d" "$pct")%"
fi

clock_now=$(date +"%H:%M")
hour24=$(( 10#$(date +"%H") ))
if   [ "$hour24" -ge 5 ]  && [ "$hour24" -lt 7 ];  then clock_icon="🌄"
elif [ "$hour24" -ge 7 ]  && [ "$hour24" -lt 12 ]; then clock_icon="🌅"
elif [ "$hour24" -ge 12 ] && [ "$hour24" -lt 16 ]; then clock_icon="☀️"
elif [ "$hour24" -ge 16 ] && [ "$hour24" -lt 19 ]; then clock_icon="🌇"
elif [ "$hour24" -ge 19 ] && [ "$hour24" -lt 22 ]; then clock_icon="🌆"
else                                                    clock_icon="🌙"
fi

model_segment="${model_icon}  ${C_CYAN}${model}${C_RESET}"

place_segment=""
if [ -n "$folder" ]; then
    place_segment="${folder_icon}  ${C_BLUE}${folder}${C_RESET}"
    if [ -n "$git_branch" ]; then
        place_segment="${place_segment}  ${C_MAGENTA}${git_icon} ${git_branch}${git_status}${git_ahead_behind}${C_RESET}"
    fi
fi

todo_segment=""
if [ -n "$session_task_line" ]; then
    t_done=$(echo   "$session_task_line" | awk '{print $1+0}')
    t_doing=$(echo  "$session_task_line" | awk '{print $2+0}')
    t_pending=$(echo "$session_task_line" | awk '{print $3+0}')
    t_total=$(( t_done + t_doing + t_pending ))
    if [ "$t_total" -gt 0 ]; then
        if   [ "$t_done" -eq "$t_total" ]; then task_color="$C_GREEN"
        elif [ "$t_doing" -gt 0 ];         then task_color="$C_YELLOW"
        else                                    task_color="$C_ORANGE"
        fi
        task_parts=""
        [ "$t_doing"   -gt 0 ] && task_parts="${task_parts} ${t_doing}⚙"
        [ "$t_done"    -gt 0 ] && task_parts="${task_parts} ${t_done}✓"
        [ "$t_pending" -gt 0 ] && task_parts="${task_parts} ${t_pending}○"
        task_parts=${task_parts# }
        todo_segment="🎯  ${task_color}${task_parts}${C_RESET}"
    fi
elif [ -n "$todo_count" ] && [ "$todo_count" -gt 0 ]; then
    todo_segment="📋  ${C_ORANGE}${todo_count}${C_RESET}"
fi

session_segment=""
[ "$CCSL_SHOW_SESSION_NAME" = "1" ] && [ -n "$session_name" ] && session_segment="💬  ${C_YELLOW}${session_name}${C_RESET}"

time_segment=""
[ "$CCSL_SHOW_ELAPSED" = "1" ] && [ -n "$elapsed_str" ] && time_segment="${time_icon}  ${C_MUTED}${elapsed_str}${C_RESET}"

context_segment=""
[ -n "$progress_bar" ] && context_segment="${ctx_icon}  ${progress_bar}"

clock_segment=""
[ "$CCSL_SHOW_CLOCK" = "1" ] && clock_segment="${clock_icon}  ${C_GREY}${clock_now}${C_RESET}"

line1=("$model_segment")
[ -n "$place_segment" ]   && line1+=("$place_segment")
[ -n "$session_segment" ] && line1+=("$session_segment")

line2=()
join_group() {
    local joined="" p
    for p in "$@"; do
        [ -z "$p" ] && continue
        if [ -z "$joined" ]; then joined="$p"
        else joined="${joined}  ${p}"
        fi
    done
    printf "%s" "$joined"
}

time_group=$(join_group "$time_segment" "$clock_segment")
capacity_group=$(join_group "$session_usage_segment" "$week_usage_segment" "$context_segment")

[ -n "$todo_segment" ]    && line2+=("$todo_segment")
[ -n "$time_group" ]      && line2+=("$time_group")
[ -n "$cost_segment" ]    && line2+=("$cost_segment")
[ -n "$capacity_group" ]  && line2+=("$capacity_group")

separator="${C_DIM} │ ${C_RESET}"

render_line() {
    local out="$1"; shift
    local p
    for p in "$@"; do out="${out}${separator}${p}"; done
    printf "%b" "$out"
}

render_line "${line1[@]}"
[ "${#line2[@]}" -gt 0 ] && { printf "\n"; render_line "${line2[@]}"; }
