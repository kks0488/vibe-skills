# vibe-codex (Codex CLI)

This repo is **Codex-first** and keeps distributable skill sources under `skills`.

## Repo conventions

- Keep `scripts/*.sh` and `scripts/*.ps1` feature-parity (same subcommands + flags).
- Skills live in `skills/<skill>/SKILL.md` (+ optional `agents/openai.yaml` UI metadata + dependency hints; optional legacy `SKILL.json`). Tip: keep `agents/openai.yaml` JSON-formatted (JSON ⊂ YAML) so doctor scripts can validate without extra deps.
- Current OpenAI documentation lists `.agents/skills` for local discovery. New installs should target `.agents/skills` via `--agents`; the root `skills` directory also supports plugin packaging.
- For `SKILL.md` YAML frontmatter, keep `name` ≤ 64, `description` ≤ 1024, and `metadata.short-description` ≤ 1024.
- When changing skills, keep `SKILL.md` ↔ `agents/openai.yaml` (and `SKILL.json` if present) aligned and run `bash scripts/doctor.sh`.
- Avoid creating backup folders inside any skills directory (Codex loads skills recursively and backups can become duplicate skills).
- Do not describe `vc teams` as Codex-native. It is a persistent mailbox companion; built-in Codex subagents perform actual in-session delegation.
- Do not add guaranteed-success, infinite-retry, or never-ask instructions. Use bounded recovery and truthful blockers.

## OpenAI docs

- Prefer the OpenAI Developer Docs MCP server when you need up-to-date OpenAI/Codex/API info.
  - Setup: `vc mcp docs` (or `codex mcp add openaiDeveloperDocs --url https://developers.openai.com/mcp`)

## Handy commands

- Diagnose: `bash scripts/doctor.sh` (or `pwsh scripts/doctor.ps1`)
- Install skills: `bash scripts/install-skills.sh [--agents]` (or `pwsh scripts/install-skills.ps1 [--agents]`)
- MCP helpers: `vc mcp docs`, `vc mcp skills`, `vc mcp list`
