# vibe-skills

AI-first skills for vibe coding. Adapted from the official Claude skills set, tuned for fast autonomous loops in Codex and OpenCode. This repo is for my own day-to-day use (even if I am not a coder), not just for GitHub. Humans can skim; the AI does the reading and deciding.

## Who this is for

- Vibe coders who want outcomes fast
- People who prefer "tell AI the goal, review the result"
- Teams that want a clean author/reviewer loop with Git as the source of truth
- Non-technical users who want AI to choose and run the right skill

## Quick Start

1. Install skills into your agent's skills directory.
   - Codex default: `~/.codex/skills`
   - Example (copy this repo):
     ```bash
     cp -R skills ~/.codex/skills
     ```
2. Invoke a skill by name in chat:
   - `use vibe-phase-loop`
   - `$git-dual-terminal-loop`
   - `use vibe-router: <goal>`
3. Let the AI run; give feedback after the first pass.

## Recommended skills (vibe-first)

- `vibe-phase-loop`: 10/20 phase plan -> execute -> test -> replan
- `vibe-router`: auto-pick and run the right skill
- `git-dual-terminal-loop`: 2-terminal author/reviewer PR workflow
- `frontend-design`: bold UI builds without overthinking
- `webapp-testing`: smoke test first, then deeper checks
- `docx` / `pptx` / `pdf` / `xlsx`: document workflows

## Two-terminal loop (fastest workflow)

- Terminal A: Author (edits, commits, pushes)
- Terminal B: Reviewer (diffs, tests, comments)
- Use PRs for all feedback; keep edits on A only
- OpenCode mapping: A=`build`, B=`plan`
- Codex role prompts are in `skills/git-dual-terminal-loop/SKILL.md`

## What is inside

- `skills/`: the skills
- `spec/`: agent skills spec (reference)
- `template/`: skill template

## Notes

- These skills are adapted from the official Claude skills set and upgraded for vibe coding.
- Each skill includes "Vibe Defaults" and "Vibe Fast Path" so the AI can act without waiting.
