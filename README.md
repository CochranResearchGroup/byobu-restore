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
./install.sh
```

This installs:

```text
~/.local/lib/byobu-session-state/bin/byobu-session-state
~/.local/bin/byobu-session-state -> ~/.local/lib/byobu-session-state/bin/byobu-session-state
```

Make sure `~/.local/bin` is on your `PATH`.

## Usage

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
