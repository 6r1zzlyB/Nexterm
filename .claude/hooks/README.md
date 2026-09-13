# Project hooks

Hooks are configured in `.claude/settings.json` under a `hooks` key (or in
`.claude/settings.local.json` for personal, untracked ones) — there is no separate hook file
format to place under this directory. This directory exists as a home for hook *scripts*
referenced from that config, e.g. `${CLAUDE_PLUGIN_ROOT}`-relative shell scripts a
`PreToolUse`/`PostToolUse` hook shells out to.

Example inline config (add the `hooks` key to `.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "prompt", "prompt": "Validate file write safety. Check: system paths, credentials, path traversal, sensitive content. Return 'approve' or 'deny'." }
        ]
      }
    ]
  }
}
```

Available events: `PreToolUse`, `PostToolUse`, `Stop`, `SubagentStop`, `SessionStart`,
`SessionEnd`, `UserPromptSubmit`, `PreCompact`, `Notification`. Only add a hook when a rule in
`CLAUDE.md` or `.claude/rules/` genuinely cannot be trusted to run without enforcement — most
projects need none.
