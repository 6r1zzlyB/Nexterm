# Bash script conventions

- Every script starts with `#!/usr/bin/env bash` and `set -euo pipefail` — no exceptions.
  Document any deliberate deviation (e.g. a line that must tolerate a nonzero exit) with a
  comment saying why, immediately above it.
- Run `mise run lint` (shellcheck) before calling any script change done; treat every shellcheck
  warning as blocking unless there's a documented, deliberate `# shellcheck disable=SCxxxx` with
  a reason on the same line.
- A header comment states: purpose, usage, and any required environment variables or arguments —
  same shape `claude-config`'s own `install.py` docstring uses.
