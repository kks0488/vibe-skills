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

## Vibe Quick Invoke

- `use vibe-router: <goal>`
- `just do this: <goal>`
- `아무것도 모르겠다. <goal> 끝까지 해줘`
- `끝까지: <goal>`
- `그냥해줘: <goal>`
- `걍해줘: <goal>`
- `ㄱㄱ: <goal>`
- `마무리까지 해줘: <goal>`

## Vibe Finish

If the user says any of the following, route to `vibe-phase-loop` and finish end-to-end:
- "아무것도 모르겠다"
- "끝까지 해줘"
- "끝까지"
- "그냥해줘"
- "걍해줘"
- "ㄱㄱ"
- "마무리까지"
- "finish it"
- "take it to the end"

## Routing Rules

- Finish-to-end requests: `vibe-phase-loop`
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
- For finish-to-end requests, avoid mid-stream questions; capture decisions at the end.
