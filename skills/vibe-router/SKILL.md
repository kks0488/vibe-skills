---
name: vibe-router
description: Select and apply the right skill automatically. Use when the user does not know which skill to use, says "just do it", or wants the AI to decide the best skill and execute it with minimal questions.
---

# Vibe Router

## Vibe Defaults

- Prefer fast iteration and shipping a working baseline over perfection.
- Make safe default choices without pausing; record assumptions briefly.
- Ask questions only after delivering an initial result, unless the workflow requires confirmation for safety/legal reasons.
- Keep outputs concise, actionable, and easy to extend.
- Assume the user is non-technical; avoid long explanations and provide copy/paste steps when actions are required.

## Vibe Fast Path

- Classify the task in one pass.
- Select a single best-fit skill; avoid chaining unless required.
- Execute immediately; collect assumptions and questions for the end.
- If the task is multi-step or open-ended, default to `vibe-phase-loop`.

## Routing Rules

- Planning/execution loops: `vibe-phase-loop`
- Two-terminal Git workflow: `git-dual-terminal-loop`
- Frontend UI build: `frontend-design`
- Multi-file React artifact: `web-artifacts-builder`
- Web app testing: `webapp-testing`
- Docs/office files: `docx`, `pptx`, `pdf`, `xlsx`
- Theming: `theme-factory`
- Branding: `brand-guidelines`
- MCP servers: `mcp-builder`
- Art or posters: `algorithmic-art` or `canvas-design`
- Internal updates/comms: `internal-comms`
- New skill creation: `skill-creator`

## Execution Rules

- Read only the selected skill's SKILL.md and follow its defaults.
- Keep the user flow simple: deliver a first pass, then ask for corrections.
- If uncertain between two skills, pick the one with narrower scope.
