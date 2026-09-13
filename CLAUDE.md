# nexterm-snippets

Scripts and snippets source for [Nexterm](https://github.com/gnmyt/Nexterm), consumed as a
**Source** URL so the repo's content appears directly in Nexterm's Scripts/Snippets menus.

## Purpose
Central, version-controlled home for read-only diagnostic scripts and terminal snippets used
across the Saint Denis Enterprises host fleet via Nexterm. If it disappears, Nexterm's Scripts
and Snippets menus go empty and hosts lose their one-click diagnostics.

## Stack
Bash (`.sh`), plus raw terminal snippets (`.snippet`). No build step, no runtime dependency
beyond a POSIX shell and whatever CLI tools each script guards with `command -v`.

## Layout
- `*.sh` — scripts run as a file on the target server (docker/storage/network/journal reports).
- `*.snippet` — pasted directly into the terminal (quick one-liners, Claude session controls).
- `NTINDEX` — manifest Nexterm reads from the repo root; a file not listed here is invisible to
  Nexterm regardless of validity. Regenerate after every add/change (see README "NTINDEX").
- `@name`/`@description`/`@os` metadata lives in leading `#` comments in each file; `@os` must
  match Nexterm's fixed OS name list exactly (see README) or the entry silently matches nothing.

## Conventions
- Everything here is read-only — destructive actions print the command instead of running it
  (e.g. `docker-disk-report.sh` never runs the prune commands it prints).
- Guard every optional tool with `command -v` and degrade with a clear message; never require root.
- Bound anything that scans logs or walks a filesystem; wrap NFS/network probes in `timeout`.
- `NTINDEX` hashes must be computed from the git-committed (LF) bytes, not a CRLF working copy —
  use `git show ":<file>" | md5sum`, not a raw local `md5sum`.

## Verify
`mise run check` (shellcheck on every tracked `.sh` file). No test suite. Manually paste snippet
changes into a test terminal. Regenerate and diff `NTINDEX` after any file add/change.

## Known Anti-Patterns
