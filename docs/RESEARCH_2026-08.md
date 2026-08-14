# Vibe Codex research update - August 2026

This note records what changed after several months of practical use and a refresh against current
official OpenAI documentation.

## What repeated use exposed

### 1. Fixed phase counts were ceremony, not control

The previous workflow required 10 phases, or 20 for large work. Small bug fixes spent more effort
maintaining a plan than solving the problem. Large tasks still needed decomposition based on actual
dependencies, not an arbitrary number.

Decision: use three sizes. Small work goes directly from scope to execution and verification.
Multi-step work gets a short explicit plan. Long-running work gets a durable work document with
requirements, decisions, blockers, and evidence.

### 2. Infinite retry hid real blockers

Repeating a failing method did not create autonomy. It consumed time and sometimes moved farther from
the user's goal.

Decision: use a Two-Strike rule. After the same failure twice, stop repeating the approach, inspect
the root cause, and re-plan. If progress needs new authority, credentials, money, or an external state
change, report the blocker truthfully.

### 3. "Never ask" was unsafe

Reasonable implementation details can be decided autonomously. Product direction, irreversible
changes, credential handling, publication, and spending cannot always be guessed safely.

Decision: proceed on reversible in-scope work; ask when an unanswered choice materially changes the
result or requires authority the user has not granted.

### 4. Mandatory logs became context noise

Updating a work file after every command created low-value churn and could distract from requirements.

Decision: create a work document only for multi-step or resumable tasks, and update it at decision or
phase boundaries rather than after every action.

### 5. Native subagents changed the coordination boundary

Current Codex releases include subagent workflows. They are useful for independent, read-heavy work
such as exploration, test execution, triage, and summarization. Parallel write-heavy work needs more
care because it can create conflicts.

Decision: use Codex subagents for normal in-session parallelism. Keep `vc teams` as an optional local
mailbox for durable, cross-process coordination. The mailbox does not spawn agents and is not labeled
as a native Codex runtime.

## Current official skill model

The August 2026 documentation describes a skill as a directory containing required `SKILL.md`
instructions and optional scripts, references, assets, and `agents/openai.yaml` metadata. Skills use
progressive disclosure: the host starts from name and description, then loads the full instructions
when the skill is selected.

For local discovery, Codex scans `.agents/skills` from the working directory toward the repository
root and also reads user skills from `~/.agents/skills`. Explicit invocation uses `/skills` or
`$skill-name`; matching descriptions allow implicit invocation. Distributable bundles should move
toward the plugin format.

Vibe Codex therefore:

- recommends `.agents/skills` for new installs;
- keeps each skill description narrow and trigger-oriented;
- synchronizes `SKILL.md` with `agents/openai.yaml` metadata;
- keeps legacy `SKILL.json` and `$CODEX_HOME/skills` support only for compatibility;
- treats a future plugin package as the preferred distribution direction.
- includes a plugin manifest in v0.5.0 while retaining the existing installer for compatibility.

## Sources checked

- [Build skills](https://learn.chatgpt.com/docs/build-skills)
- [Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [Codex for Open Source](https://developers.openai.com/community/codex-for-oss)

Documentation changes over time. Recheck these sources before changing compatibility claims.
