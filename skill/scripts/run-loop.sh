#!/usr/bin/env bash
# Run a research loop from the shell, one fresh agent session per iteration.
#
# Use this on hosts without a scheduler (Codex CLI, Pi, Cursor, plain
# terminals), or whenever you want each iteration to start with a clean context.
#
#   run-loop.sh DATAROOM [--agent claude|codex|pi] [--interval SECONDS] [--iterations N]
#
# The loop stops when `dataroom.py status` says STOP, after --iterations runs,
# when an iteration leaves the dataroom failing `check`, or on Ctrl-C.
# To run another agent, set RESEARCH_LOOP_CMD to a command that accepts the
# prompt as its final argument, for example RESEARCH_LOOP_CMD='my-agent --print'.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATAROOM_PY="$SKILL_DIR/scripts/dataroom.py"

usage() {
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

[[ $# -ge 1 ]] || usage 1
[[ $1 == -h || $1 == --help ]] && usage 0
ROOM="$(cd "$1" && pwd)"
shift
AGENT=claude
INTERVAL=60
MAX_RUNS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent) AGENT="$2"; shift 2 ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    --iterations) MAX_RUNS="$2"; shift 2 ;;
    -h|--help) usage 0 ;;
    *) echo "unknown option: $1" >&2; usage 1 ;;
  esac
done

PROMPT="Use the research-loop skill to run exactly one iteration for the dataroom at $ROOM. \
Follow the skill's 'Run one iteration' steps, including the closing log and check, then stop."

run_agent() {
  if [[ -n "${RESEARCH_LOOP_CMD:-}" ]]; then
    # shellcheck disable=SC2086
    (cd "$ROOM" && $RESEARCH_LOOP_CMD "$PROMPT")
    return
  fi
  case "$AGENT" in
    claude)
      # Tools are limited to reading the web and editing files; the only shell
      # command allowed is the dataroom helper.
      (cd "$ROOM" && claude -p "$PROMPT" \
        --allowedTools "Read,Write,Edit,Glob,Grep,WebSearch,WebFetch,Skill,Bash(python3 $DATAROOM_PY:*)")
      ;;
    codex)
      codex --search exec --skip-git-repo-check -s workspace-write -C "$ROOM" "$PROMPT"
      ;;
    pi)
      (cd "$ROOM" && pi -p "$PROMPT")
      ;;
    *)
      echo "unknown agent: $AGENT (use claude, codex, pi, or set RESEARCH_LOOP_CMD)" >&2
      exit 1
      ;;
  esac
}

runs=0
while :; do
  if python3 "$DATAROOM_PY" status "$ROOM" | grep -q '^STOP'; then
    python3 "$DATAROOM_PY" status "$ROOM"
    echo "The loop has reached a stop condition. Ask the agent to close it and write the synthesis."
    exit 0
  fi
  before="$(python3 "$DATAROOM_PY" status "$ROOM" --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["iteration"])')"
  echo "== $(date '+%Y-%m-%d %H:%M') iteration $((before + 1))"
  run_agent || echo "warning: the agent exited with status $?" >&2
  after="$(python3 "$DATAROOM_PY" status "$ROOM" --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["iteration"])')"
  if [[ "$after" == "$before" ]]; then
    echo "warning: the iteration did not close with dataroom.py log" >&2
  fi
  if ! python3 "$DATAROOM_PY" check "$ROOM"; then
    echo "The dataroom fails its check; stopping so the errors can be fixed." >&2
    exit 1
  fi
  runs=$((runs + 1))
  if [[ "$MAX_RUNS" -gt 0 && "$runs" -ge "$MAX_RUNS" ]]; then
    exit 0
  fi
  sleep "$INTERVAL"
done
