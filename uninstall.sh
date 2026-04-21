#!/usr/bin/env bash
set -euo pipefail

install_root="${INSTALL_ROOT:-$HOME/.local/lib/byobu-session-state}"
bin_root="$install_root/bin"
user_bin="${USER_BIN_DIR:-$HOME/.local/bin}"

rm -f "$user_bin/byobu-session-state"
rm -f "$bin_root/byobu-session-state"
rmdir "$bin_root" 2>/dev/null || true
rmdir "$install_root" 2>/dev/null || true

cat <<EOF
Removed byobu-session-state.

Saved snapshots were not removed. Default snapshot directory:
  $HOME/.local/state/byobu-session-state
EOF
