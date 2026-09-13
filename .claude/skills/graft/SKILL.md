---
name: graft
description: Use for code-navigation questions in this repo: where a symbol is defined, what calls it, what a change would break. Query graft before grepping or reading source.
---

# graft

Query graft before grepping or reading source. Use the MCP tool
`graft_find_code` to locate a symbol's definition, `graft_trace_calls` to see
what calls it or what it calls, and `graft_find_all` for exhaustive pattern
search. Fall back to plain `grep`/`ripgrep` only when graft has no match (the
index may be stale or the code unindexed) or when you already know the exact
`file:line` and just need to read it.

`graft/` is the local graph cache. It is git-ignored and regenerable via
`graft build` — never edit or commit it.
