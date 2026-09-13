# Project skills

Project-specific skills only. A skill belongs here when it packages a repeatable procedure
that's specific to this repo (a deploy sequence, a local test-data seeding routine) — not
something already covered by a fleet-wide skill in `claude-config`'s `skills/` (account-synced)
or an installed plugin.

Each skill is a directory containing `SKILL.md` with YAML frontmatter (`name`, `description`,
optionally `version`). See `_example/SKILL.md` for the minimal valid shape. Delete `_example/`
once a real skill exists, or keep it as a template if the project expects to grow more than one.
