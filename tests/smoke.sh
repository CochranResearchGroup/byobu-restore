#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
snapshot_dir=$(mktemp -d)

cleanup() {
  tmux kill-session -t byobu-state-test >/dev/null 2>&1 || true
  tmux kill-session -t byobu-state-restored >/dev/null 2>&1 || true
  rm -rf "$snapshot_dir"
}
trap cleanup EXIT

tmux kill-session -t byobu-state-test >/dev/null 2>&1 || true
tmux kill-session -t byobu-state-restored >/dev/null 2>&1 || true

tmux new-session -d -s byobu-state-test -n editor -c /tmp
tmux split-window -t byobu-state-test:0 -c /var/tmp
tmux select-layout -t byobu-state-test:0 even-horizontal >/dev/null 2>&1 || true
tmux new-window -t byobu-state-test: -n home -c "$HOME"
tmux select-window -t byobu-state-test:1

BYOBU_SESSION_STATE_DIR="$snapshot_dir" "$repo_root/bin/byobu-session-state" save smoke byobu-state-test
tmux kill-session -t byobu-state-test
BYOBU_SESSION_STATE_DIR="$snapshot_dir" "$repo_root/bin/byobu-session-state" restore smoke byobu-state-restored

windows=$(tmux list-windows -t byobu-state-restored -F '#{window_index}:#{window_name}' | paste -sd ',' -)
[ "$windows" = "0:editor,1:home" ] || {
  echo "unexpected windows: $windows" >&2
  exit 1
}

pane_paths=$(tmux list-panes -t byobu-state-restored:0 -F '#{pane_current_path}' | paste -sd ',' -)
[ "$pane_paths" = "/tmp,/var/tmp" ] || {
  echo "unexpected pane paths: $pane_paths" >&2
  exit 1
}

if command -v byobu-tmux >/dev/null 2>&1; then
  status_left=$(tmux show-options -gqv status-left)
  case "$status_left" in
    *byobu-status*) ;;
    *)
      echo "restored session does not appear to have Byobu status loaded: $status_left" >&2
      exit 1
      ;;
  esac
fi

echo "smoke test passed"
