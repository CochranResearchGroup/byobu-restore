#!/usr/bin/env bash
set -euo pipefail

install_root="${INSTALL_ROOT:-$HOME/.local/lib/byobu-restore}"
user_bin="${USER_BIN_DIR:-$HOME/.local/bin}"
unit_dir="${SYSTEMD_USER_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user}"

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user disable --now byobu-session-autosave.timer >/dev/null 2>&1 || true
fi

rm -f "$user_bin/byobu-restore" "$user_bin/byobu-session-state"
rm -f "$unit_dir/byobu-session-autosave.service" "$unit_dir/byobu-session-autosave.timer"
rm -f "$install_root/bin/byobu-restore" "$install_root/bin/byobu-session-state"
rm -f "$install_root/libexec/byobu-session-autosave"
rmdir "$install_root/bin" "$install_root/libexec" "$install_root" 2>/dev/null || true

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

cat <<EOF
Removed byobu-restore. Saved snapshots were retained at:
  $HOME/.local/state/byobu-session-state
EOF
