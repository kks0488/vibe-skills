---
name: vc-router
description: Select the smallest suitable Vibe Codex workflow for a request. Use when the user wants help choosing between direct execution, the phase loop, or durable mailbox coordination.
metadata:
  short-description: Route a request to the smallest suitable VC workflow.
---

# VC Router

## Route once, then work

Classify the request by outcome, scope, risk, and need for persistence. Select one primary path:

- Simple answer or one-step reversible change: handle directly without another VC skill.
- Multi-step implementation or repair with end-to-end verification: use `vc-phase-loop`.
- Durable or cross-process coordination: use `vc-agent-teams` for the mailbox and use built-in Codex
  subagents for actual in-session delegated work.

Do not force every request through the phase loop. Do not chain skills when one workflow is enough.

## Routing rules

1. Respect the user's explicit skill choice when it fits the task.
2. Prefer the narrowest workflow that can produce the requested evidence.
3. Use safe defaults for reversible implementation details.
4. Ask when a missing decision changes scope, authority, safety, or public impact.
5. If no VC workflow adds value, continue directly and say so briefly.

## Output

State the selected path in one sentence, then execute it. Avoid long routing analyses.
