---
name: vc-phase-loop
description: Run a bounded evidence-first plan, execute, and verify workflow for multi-step implementation or repair tasks. Use when the user wants end-to-end completion; do not use for a simple answer or when a required decision needs user authority.
metadata:
  short-description: Adaptive plan, execute, recover, and verify workflow.
---

# VC Phase Loop

## Outcome

Complete the requested work within the user's scope and authority, then support the completion claim
with executed checks and concrete evidence.

## 1. Scope and risk

- Read applicable repository instructions before editing.
- Separate requirements from assumptions.
- Identify destructive, costly, credential-sensitive, public, or externally consequential actions.
- Proceed with reversible in-scope choices. Ask when an unanswered choice materially changes the
  result or requires authority the user has not granted.

## 2. Choose task depth

- Small: execute directly, then verify.
- Multi-step: keep a short plan with one active step.
- Long-running or resumable: create `.vc/work-{timestamp}.md` with requirements, decisions, status,
  blockers, and completion evidence. Update it at decision or phase boundaries, not after every command.

Do not inflate a task to reach a fixed phase count.

## 3. Execute

- Follow existing project patterns.
- Keep changes minimal and reviewable.
- Use built-in Codex subagents only for independent work that benefits from separate context, such as
  exploration, test execution, or review.
- Avoid parallel write-heavy work unless file ownership is clearly separated.
- Preserve user changes and stay within the approved roots.

## 4. Recover intelligently

Use the Two-Strike rule:

1. Diagnose the first failure and try a targeted correction.
2. If the same failure repeats, stop using the same approach.
3. Re-check assumptions, inspect the root cause, and choose a materially different strategy.
4. If progress requires missing authority, credentials, money, user input, or external state, report
   the blocker instead of pretending to continue.

Retries are bounded by new information. Never promise guaranteed success or an infinite loop.

## 5. Verify proportionally

Prefer the project's own checks in this order when available:

1. focused tests for changed behavior;
2. lint, type, or syntax checks;
3. broader tests or build for higher-risk changes;
4. a real user-path exercise when practical.

Do not claim a check passed unless it ran successfully. If a check could not run, state why.

## 6. Report

Lead with the outcome. Include:

- what changed;
- commands or user paths actually verified;
- important assumptions or tradeoffs;
- remaining blockers or follow-up work.
