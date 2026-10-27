#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)

cleanup() { rm -rf -- "$test_root"; }
trap cleanup EXIT

mkdir -p "$test_root/fake-bin"
# The generated shim expands these variables when it runs, not while written.
# shellcheck disable=SC2016
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "$TEST_SYSTEMCTL_LOG"\n' > "$test_root/fake-bin/systemctl"
chmod 0755 "$test_root/fake-bin/systemctl"

export HOME="$test_root/home"
export INSTALL_ROOT="$test_root/install"
export USER_BIN_DIR="$test_root/user-bin"
export SYSTEMD_USER_DIR="$test_root/systemd"
export TEST_SYSTEMCTL_LOG="$test_root/systemctl.log"
export PATH="$test_root/fake-bin:$PATH"

"$repo_root/install.sh" --no-enable >/dev/null
[ -x "$INSTALL_ROOT/bin/byobu-restore" ]
[ -x "$INSTALL_ROOT/bin/byobu-session-state" ]
[ -x "$INSTALL_ROOT/libexec/byobu-session-autosave" ]
[ -L "$USER_BIN_DIR/byobu-restore" ]
[ -f "$SYSTEMD_USER_DIR/byobu-session-autosave.timer" ]
[ ! -e "$TEST_SYSTEMCTL_LOG" ]
"$USER_BIN_DIR/byobu-restore" --version | grep -qx 'byobu-restore 1.1.1'

"$repo_root/uninstall.sh" >/dev/null
[ ! -e "$USER_BIN_DIR/byobu-restore" ]
[ ! -e "$SYSTEMD_USER_DIR/byobu-session-autosave.timer" ]
[ -e "$TEST_SYSTEMCTL_LOG" ]

printf 'install test passed\n'
