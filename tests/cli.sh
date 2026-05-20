#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
snapshot_dir=$(mktemp -d)

cleanup() {
  tmux kill-session -t byobu-state-cli >/dev/null 2>&1 || true
  rm -rf "$snapshot_dir"
}
trap cleanup EXIT

run_cli() {
  BYOBU_SESSION_STATE_DIR="$snapshot_dir" "$repo_root/bin/byobu-session-state" "$@"
}

run_cli --version | grep -Eq '^byobu-session-state [0-9]+\.[0-9]+\.[0-9]+$'

if run_cli save bad/name byobu-state-cli >/tmp/byobu-state-cli.out 2>/tmp/byobu-state-cli.err; then
  echo "expected invalid snapshot name to fail" >&2
  exit 1
fi
grep -q 'snapshot name must be a simple name' /tmp/byobu-state-cli.err

tmux new-session -d -s byobu-state-cli -n cli -c /tmp
run_cli save cli byobu-state-cli >/tmp/byobu-state-cli.out
snapshot_path="$snapshot_dir/cli.snapshot"
[ -f "$snapshot_path" ] || {
  echo "expected snapshot to exist: $snapshot_path" >&2
  exit 1
}

chmod 0666 "$snapshot_path"
if run_cli restore cli byobu-state-cli-restored >/tmp/byobu-state-cli.out 2>/tmp/byobu-state-cli.err; then
  echo "expected writable snapshot restore to fail" >&2
  exit 1
fi
grep -q 'refusing to restore group/world-writable snapshot' /tmp/byobu-state-cli.err

echo "cli test passed"
