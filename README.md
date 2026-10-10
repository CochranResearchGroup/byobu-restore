# byobu-restore

Automatic, private snapshots and one-command recovery for Byobu sessions using
the tmux backend.

`byobu-restore` saves the shape of every session every five minutes. After a
reboot, run one command to recreate the saved session named `default` and attach to it.
Repeated or concurrent invocations reuse the same shared recovery session.

It preserves:

- windows and window names
- pane counts, layouts, and working directories
- the active window and active pane

It does **not** preserve running processes, scrollback, terminal output,
unsaved editor state, or shell variables. Restored panes start fresh shells.

## Requirements

- Linux with a systemd user manager
- Bash 4.3 or newer
- Byobu using the tmux backend
- `tmux`, `flock`, and standard GNU userland tools

Ubuntu and Debian users can install the runtime dependencies with:

```bash
sudo apt-get install byobu tmux util-linux
```

## Install

```bash
git clone https://github.com/CochranResearchGroup/byobu-restore.git
cd byobu-restore
./install.sh
```

The installer copies the runtime to `~/.local/lib/byobu-restore`, links the
commands into `~/.local/bin`, installs a user-level systemd timer, and takes the
first snapshot. No root access is used by the installer.

For files only, without enabling or starting the timer:

```bash
./install.sh --no-enable
```

Ensure `~/.local/bin` is on your `PATH`.

## Recover a session

Restore the saved session named `default` and attach to it:

```bash
byobu-restore
```

The recovery session defaults to `default`. Once it exists, subsequent
runs attach to it without overwriting anything--even if snapshots have been
removed.

To use the last snapshot from the previous boot after newer snapshots exist:

```bash
byobu-restore previous-boot
```

To restore a particular saved session, pass its snapshot name as the second
argument:

```bash
byobu-restore latest session-3
```

List the snapshot names in the latest automatic save:

```bash
BYOBU_SESSION_STATE_DIR="$HOME/.local/state/byobu-session-state/autosave/latest" \
  byobu-session-state list
```

## Choose the shared session

Override the target for one invocation:

```bash
BYOBU_RESTORE_SESSION=work byobu-restore
```

To adopt an existing session as the persistent default, put its exact name in:

```text
~/.local/state/byobu-session-state/shared-session
```

The one-shot environment override does not change that saved default.

## Inspect and control autosave

```bash
systemctl --user status byobu-session-autosave.timer
systemctl --user list-timers byobu-session-autosave.timer
journalctl --user -u byobu-session-autosave.service -n 20
```

Pause or resume automatic snapshots:

```bash
systemctl --user disable --now byobu-session-autosave.timer
systemctl --user enable --now byobu-session-autosave.timer
```

The timer captures all sessions on the default tmux socket. A new snapshot is
published only when session structure changes or after a reboot; foreground
command changes alone do not rotate history. At most 12 complete automatic
saves are retained, including the last save from the
previous boot. Snapshot files use private permissions.

## Manual snapshots

The bundled `byobu-session-state` command can also create named snapshots:

```bash
byobu-session-state save work mysession
byobu-session-state list
byobu-session-state restore work work-restored
```

Manual snapshots live directly under
`~/.local/state/byobu-session-state` and are not pruned by the autosave timer.
See `byobu-session-state --help` for the full command reference.

Snapshot files are shell data files read by the restore helper. Restore only
snapshots you created or reviewed. The helper refuses snapshots not owned by
the current user or writable by a group or other users.

## Uninstall

```bash
./uninstall.sh
```

Uninstalling stops the timer and removes installed program files. Saved
snapshots are deliberately retained under
`~/.local/state/byobu-session-state`.

## Development

```bash
make test
```

Tests use isolated temporary directories and tmux servers.

## License

MIT

## Named-session restoration (1.1)

Automatic selection matches the snapshot's saved session name to the target.
It never chooses another session because that session has more windows. A
missing or ambiguous match fails with a clear error; specify a snapshot name
explicitly to migrate an older saved session into a new target name.

Existing `shared-session` preferences remain authoritative. To adopt `default`,
rename your development session and update that preference deliberately. The
app-owned `codex-bots` session can remain in autosaves without becoming the
selected development snapshot.

The Ubuntu regularizer source and installed legacy helper were compared during
this update. Retained standalone improvements include portable helper paths,
CLI validation, snapshot trust checks and optional process capture. Automatic
snapshots continue to omit process command lines. No installed scripts or live
sessions are changed by editing this repository.
