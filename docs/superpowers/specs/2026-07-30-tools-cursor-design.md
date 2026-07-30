# Cursor CLI in the tools feature

## Goal

Add the Cursor Agent CLI to the `tools` dev container feature without allowing
Grok's legacy `agent` alias to collide with Cursor's primary `agent` command.

## Feature interface

- Add an `installCursor` boolean option, defaulting to `true`.
- Run Cursor's supported installer as the remote user:
  `curl https://cursor.com/install -fsS | bash`.
- Bump the `tools` feature version.

## Command ownership

- Grok remains available as `grok`.
- After installing Grok, remove its `agent` executable and every Grok-owned
  PATH symlink to it. This includes the executable in `~/.grok/bin` and any
  symlink the installer created in `~/.local/bin` or `/usr/local/bin`.
- Cursor exclusively owns `agent`. After the Cursor installer completes,
  `/usr/local/bin/agent` points to the remote user's
  `~/.local/bin/agent` executable.
- If Cursor is disabled, the feature creates no `agent` command from Grok.

This avoids modifying global PATH ordering and works for both interactive
shells (where Grok adds `~/.grok/bin`) and non-interactive dev container
commands.

## Verification

- Add a Cursor-only scenario that confirms `agent` is installed and runnable.
- Add a Grok + Cursor scenario that confirms `grok` works, `agent` resolves to
  Cursor, and Grok's `~/.grok/bin/agent` is absent.
- Retain existing Grok-only coverage, extended as needed to ensure it does not
  supply `agent`.
