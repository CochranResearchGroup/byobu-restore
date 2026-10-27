#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
socket="$test_root/tmux.sock"
real_tmux=$(command -v tmux)

cleanup() {
  "$real_tmux" -S "$socket" kill-server >/dev/null 2>&1 || true
  rm -rf -- "$test_root"
}
trap cleanup EXIT

mkdir -p "$test_root/bin"
for command_name in tmux byobu byobu-tmux; do
  cp "$repo_root/tests/tmux-shim" "$test_root/bin/$command_name"
done
chmod 0755 "$test_root/bin/"*

export PATH="$test_root/bin:$PATH"
export TEST_REAL_TMUX="$real_tmux"
export TEST_TMUX_SOCKET="$socket"
export TEST_ATTACH_LOG="$test_root/attached"
export BYOBU_SESSION_STATE_DIR="$test_root/state"
export BYOBU_SESSION_STATE_HELPER="$repo_root/bin/byobu-session-state"
unset TMUX TMUX_PANE
export BYOBU_RESTORE_SESSION=recovered-work

if "$repo_root/bin/byobu-restore" >/dev/null 2>&1; then
  printf 'restore should fail when no snapshot exists\n' >&2
  exit 1
fi

"$real_tmux" -S "$socket" -f /dev/null new-session -d -s source -n first 'sleep 120'
"$repo_root/libexec/byobu-session-autosave" >/dev/null
"$real_tmux" -S "$socket" new-window -t source: -n second 'sleep 120'
"$repo_root/libexec/byobu-session-autosave" >/dev/null
# Explicit snapshot selection preserves legacy migration into a new name.
"$real_tmux" -S "$socket" kill-session -t source

workers=()
for _ in 1 2 3; do
  "$repo_root/bin/byobu-restore" latest session-0 >/dev/null &
  workers+=("$!")
done
for worker in "${workers[@]}"; do
  wait "$worker"
done

windows=$("$real_tmux" -S "$socket" list-windows -t '=recovered-work' -F '#W' | paste -sd ',' -)
[ "$windows" = 'first,second' ] || {
  printf 'unexpected restored windows: %s\n' "$windows" >&2
  exit 1
}
[ "$("$real_tmux" -S "$socket" list-sessions -F '#S' | grep -cx recovered-work)" -eq 1 ]
grep -q '^attach-session -t =recovered-work$' "$TEST_ATTACH_LOG"

rm -rf -- "$BYOBU_SESSION_STATE_DIR/autosave"
"$repo_root/bin/byobu-restore" previous-boot >/dev/null

# A small default must win over a larger bot session.
unset BYOBU_RESTORE_SESSION
"$real_tmux" -S "$socket" new-session -d -s default -n development 'sleep 120'
"$real_tmux" -S "$socket" new-session -d -s codex-bots -n bot-one 'sleep 120'
"$real_tmux" -S "$socket" new-window -t codex-bots: -n bot-two 'sleep 120'
"$repo_root/libexec/byobu-session-autosave" >/dev/null
"$real_tmux" -S "$socket" kill-session -t default
"$repo_root/bin/byobu-restore" >/dev/null
[ "$("$real_tmux" -S "$socket" list-windows -t '=default' -F '#W')" = development ]
"$repo_root/bin/byobu-restore" >/dev/null
[ "$("$real_tmux" -S "$socket" list-windows -t '=codex-bots' -F '#W' | wc -l)" -eq 2 ]
if BYOBU_RESTORE_SESSION=missing "$repo_root/bin/byobu-restore" >/dev/null 2>&1; then
  printf 'missing named snapshot should fail rather than restore bots\n' >&2
  exit 1
fi

# After reboot, latest may contain only recovery/bot sessions. Preserve the
# previous boot's matching session and exercise the real helper on our socket.
ln -s "$(readlink "$BYOBU_SESSION_STATE_DIR/autosave/latest")" \
  "$BYOBU_SESSION_STATE_DIR/autosave/previous-boot"
"$real_tmux" -S "$socket" kill-session -t default
"$repo_root/libexec/byobu-session-autosave" >/dev/null
if "$repo_root/bin/byobu-restore" latest >"$test_root/explicit.out" 2>&1; then
  printf 'explicit latest must not fall back to previous-boot\n' >&2
  exit 1
fi
grep -q 'No saved snapshot for session default' "$test_root/explicit.out"
"$repo_root/bin/byobu-restore" >/dev/null
[ "$("$real_tmux" -S "$socket" list-windows -t '=default' -F '#W')" = development ]
if BYOBU_RESTORE_SESSION=missing "$repo_root/bin/byobu-restore" >/dev/null 2>&1; then
  printf 'fallback must not migrate unrelated previous-boot sessions\n' >&2
  exit 1
fi
printf 'restore test passed\n'
