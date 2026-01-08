# vibe-skills

AI-first skills for vibe coding. Adapted from the official Claude skills set, tuned for fast autonomous loops in Codex and OpenCode. This repo is for my own day-to-day use (even if I am not a coder), not just for GitHub. Humans can skim; the AI does the reading and deciding.

## Super simple (copy/paste)

One-liner install/update (recommended):

Mac/Linux:
```bash
curl -fsSL https://raw.githubusercontent.com/kks0488/vibe-skills/main/bootstrap.sh | bash
```

Windows (PowerShell):
```powershell
irm https://raw.githubusercontent.com/kks0488/vibe-skills/main/bootstrap.ps1 | iex
```

Manual (still easy):

Mac/Linux:
```bash
git clone https://github.com/kks0488/vibe-skills.git && cd vibe-skills && bash scripts/install-skills.sh
```

Windows (PowerShell):
```powershell
git clone https://github.com/kks0488/vibe-skills.git; cd vibe-skills; .\scripts\install-skills.ps1
```

Then in chat:
```
use vibe-router: <goal>
```
or
```
끝까지: <goal>
```
or
```
그냥해줘: <goal>
```
or
```
ㄱㄱ: <goal>
```

Shortcut commands (after bootstrap):
```bash
vibe install
vibe update
vibe doctor
vibe list
vibe prompts
vibe go "<goal>"
```

Notes:
- One-liner uses a local clone at `~/.vibe-skills` by default.
- Set `VIBE_SKILLS_HOME` if you want a custom location.
- In Codex, you only need to say the line above; no extra setup.

## Maintenance (optional)

Check install:
```bash
bash scripts/doctor.sh
```
```powershell
.\scripts\doctor.ps1
```

List skills:
```bash
bash scripts/list-skills.sh
```
```powershell
.\scripts\list-skills.ps1
```

Uninstall (safe backup):
```bash
bash scripts/uninstall-skills.sh
```
```powershell
.\scripts\uninstall-skills.ps1
```

## Who this is for

- Vibe coders who want outcomes fast
- People who prefer "tell AI the goal, review the result"
- Teams that want a clean author/reviewer loop with Git as the source of truth
- Non-technical users who want AI to choose and run the right skill
- Me, on any PC, with zero setup pain

## Quick Start

1. Install skills into your agent's skills directory.
   - Codex default: `~/.codex/skills`
   - Example (copy this repo):
     ```bash
     cp -R skills ~/.codex/skills
     ```
   - Or use the install script (recommended):
     ```bash
     bash scripts/install-skills.sh
     ```
2. Invoke a skill by name in chat:
   - `use vibe-phase-loop`
   - `$git-dual-terminal-loop`
   - `use vibe-router: <goal>`
3. Let the AI run; give feedback after the first pass.

## Zero-reading mode

If you do not know which skill to use, just say:

```
use vibe-router: <goal>
```

The AI will pick the right skill and run it with minimal questions.

If you want the AI to finish end-to-end without explaining, say:

```
아무것도 모르겠다. <goal> 끝까지 해줘
```

## Copy/paste role prompts

Mac/Linux:
```bash
bash scripts/role-prompts.sh author
bash scripts/role-prompts.sh reviewer
```

Windows (PowerShell):
```powershell
.\scripts\role-prompts.ps1 author
.\scripts\role-prompts.ps1 reviewer
```

## Install on another PC

Mac/Linux:
```bash
git clone https://github.com/kks0488/vibe-skills.git
cd vibe-skills
bash scripts/install-skills.sh
```

Windows (PowerShell):
```powershell
git clone https://github.com/kks0488/vibe-skills.git
cd vibe-skills
.\scripts\install-skills.ps1
```

The installer copies all skills into `~/.codex/skills` (or `$CODEX_HOME/skills`) and keeps a timestamped backup if a skill already exists.

## Update on any PC

Mac/Linux:
```bash
bash scripts/update-skills.sh
```

Windows (PowerShell):
```powershell
.\scripts\update-skills.ps1
```

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
