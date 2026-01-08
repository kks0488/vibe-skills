---
name: vg
description: Short, explicit alias for vibe-router. Use only when the user explicitly invokes `use vg:` and wants the shortest reliable router command.
---

# VG (Vibe Go Alias)

## Vibe Defaults

- Prefer fast iteration and shipping a working baseline over perfection.
- Make safe default choices without pausing; record assumptions briefly.
- Ask questions only after delivering an initial result, unless the workflow requires confirmation for safety/legal reasons.
- Keep outputs concise, actionable, and easy to extend.
- Assume the user is non-technical; avoid long explanations and provide copy/paste steps when actions are required.
- Treat non-explicit triggers (e.g., "vibe go") as normal text; ask the user to rephrase using `use vg:`.

## Vibe Fast Path

- Classify the task in one pass.
- Select a single best-fit skill; avoid chaining unless required.
- Execute immediately; collect assumptions and questions for the end.
- If the task is multi-step or open-ended, default to a finish-style workflow.

## Vibe Quick Invoke

- `use vg: <goal>`

## Scope Lock (Required)

- Before any file search, determine scope roots:
  1. If a `.vibe-scope` file exists in the current directory or any parent, use the closest one.
     - Each non-empty, non-comment line is an allowed path.
     - Relative paths are resolved from the `.vibe-scope` file directory.
  2. Else, if inside a git repo, use the repo root.
  3. Else, use the current working directory.
- Only run `rg`, `find`, or any filesystem scans inside the scope roots.
- Never scan `$HOME` or `/` unless the user explicitly asks.

## Routing Rules

- Finish-to-end requests: use a finish-style plan/execute/test workflow.
- Planning/execution loops: use a finish-style plan/execute/test workflow.
- Two-terminal Git workflow: git-dual-terminal-loop
- Frontend UI build: frontend-design
- Multi-file React artifact: web-artifacts-builder
- Web app testing: webapp-testing
- Docs/office files: docx, pptx, pdf, xlsx
- Theming: theme-factory
- Branding: brand-guidelines
- MCP servers: mcp-builder
- Art or posters: algorithmic-art or canvas-design
- Internal updates/comms: internal-comms
- New skill creation: skill-creator

## Execution Rules

- Read only the selected skill's SKILL.md and follow its defaults.
- Keep the user flow simple: deliver a first pass, then ask for corrections.
- If uncertain between two skills, pick the one with narrower scope.
- If the user did not explicitly invoke `use vg:`, ask them to rephrase using `use vg:` and stop.
