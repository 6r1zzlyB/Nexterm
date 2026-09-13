# Project rules

Project-specific rules only — never copy a universal rule in here. `universal/rules/workflow.md`
and `universal/rules/memory.md` already load for every session (see `claude-config`'s
`install.py`); duplicating them here just creates a second copy to drift out of sync.

Put a `.md` file here when a convention is genuinely local to this repo: this stack's lint
command, this repo's branch-naming scheme, a domain-specific gotcha. Delete the file, don't
leave it empty, if the project stops needing it.

Loaded automatically for every session in this repo — no reference from `CLAUDE.md` required.
