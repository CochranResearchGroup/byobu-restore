# byobu-session-state

Small deterministic snapshot/restore helper for Byobu sessions using the tmux
backend.

It captures:
- tmux/Byobu windows
- pane counts
- pane layouts, which preserve split orientation and sizing
- pane current working directories
- active window and active panes

It does not capture:
- running processes
- scrollback
- command history beyond what your shell already saves

Restore uses `byobu-tmux` when available so restored sessions are initialized
with Byobu keybindings and status configuration rather than plain tmux defaults.

## Install

```bash
git clone https://github.com/CochranResearchGroup/byobu-session-state.git
cd byobu-session-state
./install.sh
```

This installs:

```text
~/.local/lib/byobu-session-state/bin/byobu-session-state
~/.local/bin/byobu-session-state -> ~/.local/lib/byobu-session-state/bin/byobu-session-state
```

Make sure `~/.local/bin` is on your `PATH`.

## Usage

Check the installed version:

```bash
byobu-session-state --version
```

Save the current attached Byobu/tmux session:

```bash
byobu-session-state save
```

Save the current session with an explicit snapshot name:

```bash
byobu-session-state save work
```

Save a specific session:

```bash
byobu-session-state save work mysession
```

Restore a snapshot:

```bash
byobu-session-state restore work
```

Restore under a different target session name:

```bash
byobu-session-state restore work work-restored
```

List snapshots:

```bash
byobu-session-state list
```

Snapshots are stored in:

```text
~/.local/state/byobu-session-state/
```

Override that location with:

```bash
BYOBU_SESSION_STATE_DIR=/path/to/snapshots byobu-session-state save work
```

## Limitations

This tool restores a session shape, not a live process tree. Restored panes open
fresh shells in the saved working directories. It does not restore running
programs, shell variables, scrollback, command output, or unsaved editor state.

Pane layouts are captured with tmux's `window_layout` value. The smoke test
verifies split orientation, sizing, and pane paths on current tmux/Byobu, but
small differences can still occur across tmux versions or very different
terminal sizes.

## Snapshot Safety

Snapshot files are shell files that `restore` sources. Only restore snapshots
you created or reviewed. The tool writes snapshots with mode `0600` and refuses
to restore group- or world-writable snapshots.

## Uninstall

```bash
./uninstall.sh
```

The uninstall script removes the installed helper and symlink. It does not remove
saved snapshots.

## Dependencies

Required:
- `bash`
- `tmux`

Recommended:
- `byobu`

On Ubuntu:

```bash
sudo apt-get install -y byobu tmux
```

## Development

Run the local checks:

```bash
make test
```

The test suite creates temporary tmux sessions and removes them when it exits.
