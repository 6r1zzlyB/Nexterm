# Project agents

Project-specific subagents only. An agent belongs here when its system prompt needs repo
knowledge that doesn't generalize — a triage agent that knows this project's log format, a
reviewer that knows this repo's specific anti-patterns. Fleet-wide agents (`scout`,
`runner`, `plan-architect`, `security-reviewer`) already come from `claude-config`'s
`plugins/std-ent/agents/` — don't redefine them here.

Each agent is a single `.md` file with YAML frontmatter. Required: `name`, `description`,
`model` (`inherit`/`sonnet`/`opus`/`haiku`), `color`. Optional: `tools` (array — omit for all
tools), `disallowedTools`, `permissionMode`, `maxTurns`. See `reviewer.md` for a minimal
read-only example.
