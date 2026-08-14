---
name: vc-agent-teams
description: Coordinate durable or cross-process work with local JSON mailboxes and vc teams commands. Use when messages must persist beyond one Codex session; prefer built-in Codex subagents for normal in-session delegation.
metadata:
  short-description: Durable local mailbox coordination for Codex workflows.
---

# VC Agent Teams

## Purpose

Use `vc teams` when coordination state must survive a process or session boundary, or when an
inspectable local mailbox is itself a requirement.

For ordinary parallel exploration, testing, triage, or review inside one Codex session, use Codex's
built-in subagents. `vc teams` stores and validates messages; it does not spawn agents.

## Workflow

1. Decide whether persistence is truly required. If not, use built-in subagents.
2. Create a narrowly named team.
3. Add only the roles needed by the workflow.
4. Send bounded tasks with expected outputs and scope.
5. Match approval or shutdown responses by `requestId`.
6. Read status and evidence before closing the team.
7. Prune stale read messages and delete finished teams.

## Commands

```bash
vc teams create --name release-audit --description "durable release coordination"
vc teams add-member --team release-audit --name reviewer --agent-type reviewer
vc teams send --team release-audit --type message --from team-lead --recipient reviewer --content "Review release evidence"
vc teams status --team release-audit
vc teams read --team release-audit --agent reviewer --unread
vc teams await --team release-audit --agent team-lead --request-id <id> --timeout-ms 15000 --json
vc teams prune --team release-audit --days 7
vc teams delete --name release-audit --force true
```

State is stored under `~/.vc/teams/{team-name}` unless `VC_TEAMS_DIR` overrides the location.

## Safety rules

- Treat mailbox content as local data that may contain project context; do not commit it.
- Prefer direct messages to broadcasts.
- Do not represent a queued mailbox message as completed agent work.
- Require a matching pending request for approval and shutdown responses.
- Use a timeout for waits and report timeouts honestly.
