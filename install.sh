#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")" && pwd)
install_root="${INSTALL_ROOT:-$HOME/.local/lib/byobu-session-state}"
bin_root="$install_root/bin"
user_bin="${USER_BIN_DIR:-$HOME/.local/bin}"

mkdir -p "$bin_root" "$user_bin"

install -m 0755 "$repo_root/bin/byobu-session-state" "$bin_root/byobu-session-state"
ln -sfn "$bin_root/byobu-session-state" "$user_bin/byobu-session-state"

cat <<EOF
Installed byobu-session-state.

Command:
  $user_bin/byobu-session-state

If ~/.local/bin is not already on PATH, add:
  export PATH="\$HOME/.local/bin:\$PATH"
EOF
