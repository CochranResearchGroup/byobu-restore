#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install_root="${INSTALL_ROOT:-$HOME/.local/lib/byobu-restore}"
user_bin="${USER_BIN_DIR:-$HOME/.local/bin}"
unit_dir="${SYSTEMD_USER_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user}"
enable=1

case "${1:-}" in
  '') ;;
  --no-enable) enable=0 ;;
  -h|--help)
    cat <<'EOF'
Usage: ./install.sh [--no-enable]

Install byobu-restore for the current user. By default the systemd user timer
is enabled and an initial snapshot is requested. Use --no-enable to install
files without changing timer state.
EOF
    exit 0
    ;;
  *)
    printf 'Unknown option: %s\n' "$1" >&2
    exit 2
    ;;
esac
[ "$#" -le 1 ] || { printf 'Too many arguments.\n' >&2; exit 2; }

for command_name in bash tmux flock; do
  command -v "$command_name" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$command_name" >&2
    exit 1
  }
done

mkdir -p "$install_root/bin" "$install_root/libexec" "$user_bin" "$unit_dir"
install -m 0755 "$repo_root/bin/byobu-restore" "$install_root/bin/byobu-restore"
install -m 0755 "$repo_root/bin/byobu-session-state" "$install_root/bin/byobu-session-state"
install -m 0755 "$repo_root/libexec/byobu-session-autosave" "$install_root/libexec/byobu-session-autosave"
install -m 0644 "$repo_root/systemd/byobu-session-autosave.service" "$unit_dir/byobu-session-autosave.service"
install -m 0644 "$repo_root/systemd/byobu-session-autosave.timer" "$unit_dir/byobu-session-autosave.timer"
ln -sfn "$install_root/bin/byobu-restore" "$user_bin/byobu-restore"
ln -sfn "$install_root/bin/byobu-session-state" "$user_bin/byobu-session-state"

if [ "$enable" -eq 1 ]; then
  command -v systemctl >/dev/null 2>&1 || {
    printf 'systemctl is required unless --no-enable is used.\n' >&2
    exit 1
  }
  systemctl --user daemon-reload
  systemctl --user enable --now byobu-session-autosave.timer
  systemctl --user start byobu-session-autosave.service
fi

cat <<EOF
Installed byobu-restore.

Commands:
  $user_bin/byobu-restore
  $user_bin/byobu-session-state

Automatic snapshots:
  $([ "$enable" -eq 1 ] && printf 'enabled' || printf 'not enabled (--no-enable)')

If $user_bin is not already on PATH, add:
  export PATH="$user_bin:\$PATH"
EOF
