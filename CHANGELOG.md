# Changelog

## v0.5.0 - 2026-08-14

Evidence-first redesign based on several months of day-to-day use.

- Replaced fixed 10/20-phase plans with task-sized planning.
- Replaced infinite retries with a Two-Strike re-plan rule and truthful blocker reporting.
- Replaced "never ask" with safe autonomy: ask when authority, scope, or irreversible choices matter.
- Made work documents optional for small tasks and useful for multi-step work.
- Updated skill activation, layout, metadata, and install guidance to current OpenAI documentation.
- Added a validated Codex plugin manifest while retaining script-based installation compatibility.
- Reframed `vc teams` as an optional persistent mailbox companion; normal parallel work should use
  Codex's built-in subagents.
- Hardened team-name validation to prevent `.` or `..` from escaping the configured mailbox root.
- Added an MIT license, provenance notice, security policy, contribution guide, and community files.
- Removed inherited example-repository files that are not part of the current Vibe Codex product.

## v0.4.1 - 2026-02-09

- Added the file-backed `vc teams` runtime and its end-to-end tests.
- Added `.agents/skills` installation support.
