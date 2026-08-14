# Vibe Codex

[![CI](https://github.com/kks0488/vibe-codex/actions/workflows/doctor.yml/badge.svg)](https://github.com/kks0488/vibe-codex/actions/workflows/doctor.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/kks0488/vibe-codex)](https://github.com/kks0488/vibe-codex/releases)

An evidence-first workflow kit for Codex CLI: focused skills, cross-platform installers, diagnostics,
and an optional persistent mailbox runtime.

Vibe Codex is an independent community project maintained by
[@kks0488](https://github.com/kks0488). It is not affiliated with or endorsed by OpenAI.

## Why v0.5.0 is smaller and stricter

After several months of real use, the original "ultimate" workflow exposed four recurring problems:

- fixed 10/20-phase plans added overhead to small tasks;
- infinite retries could repeat a bad approach and waste time or tokens;
- "never ask" encouraged guesses when a decision actually belonged to the user;
- a custom mailbox was useful for durable coordination, but unnecessary for normal in-session
  parallel work now handled by Codex subagents.

v0.5 keeps the useful parts: scope control, safe autonomy, adaptive planning, a Two-Strike re-plan
rule, proportional testing, and completion claims backed by evidence. See
[`docs/RESEARCH_2026-08.md`](docs/RESEARCH_2026-08.md) for the research notes and design decisions.

## Included skills

| Skill | Purpose |
|---|---|
| `$vc-router` | Select the smallest suitable workflow instead of forcing every task through a large loop. |
| `$vc-phase-loop` | Run a bounded plan → execute → verify loop for multi-step work. |
| `$vc-agent-teams` | Coordinate durable or cross-process work through local JSON mailboxes. |
| `$vcg` | Explicit short alias for `$vc-router`. |
| `$vcf` | Explicit short alias for `$vc-phase-loop`. |

Codex can invoke matching skills implicitly. In Codex CLI or the IDE extension, `/skills` opens the
picker and `$skill-name` invokes a skill explicitly.

## Install

Requirements: Git and a current Codex CLI. Node.js is only required for `vc teams`.

```bash
git clone https://github.com/kks0488/vibe-codex.git ~/.vc-skills
cd ~/.vc-skills
bash scripts/install-skills.sh --agents
```

PowerShell:

```powershell
git clone https://github.com/kks0488/vibe-codex.git "$HOME/.vc-skills"
Set-Location "$HOME/.vc-skills"
pwsh -NoProfile -File scripts/install-skills.ps1 --agents
```

The recommended target is `~/.agents/skills`, matching current OpenAI documentation. Legacy
`$CODEX_HOME/skills` installation remains available by omitting `--agents` for existing users.

The repository also includes `.codex-plugin/plugin.json`, so the same five skills can be packaged
through the current Codex plugin distribution model. The copy-based installer remains available for
CLI users and backwards compatibility.

Run the diagnostic after installation:

```bash
bash scripts/doctor.sh --strict
```

See [`docs/codex-setup.md`](docs/codex-setup.md) for repo-scoped installation, metadata, and the
optional OpenAI Developer Docs MCP configuration.

## Use

Use the skill picker or invoke a skill directly:

```text
$vcg triage this failing test and choose the smallest safe workflow
$vcf implement this approved migration and provide completion evidence
```

The helper prints prompts you can paste into Codex:

```bash
vc go "triage the failing tests"
vc finish "implement the approved migration"
```

### Durable mailbox coordination

Codex's built-in subagents are the default for independent in-session exploration, testing, and
review. Use `vc teams` only when work must persist across processes or needs an inspectable local
mailbox:

```bash
vc teams create --name release-audit --description "durable release coordination"
vc teams add-member --team release-audit --name reviewer --agent-type reviewer
vc teams send --team release-audit --type message --from team-lead --recipient reviewer --content "Review release evidence"
vc teams status --team release-audit
```

`vc teams` stores JSON under `~/.vc/teams`. It coordinates messages; it does not spawn Codex agents.

## Verification

```bash
bash scripts/doctor.sh --strict
node --test scripts/vc-teams.test.mjs
```

CI runs shell and PowerShell diagnostics plus the Node end-to-end suite.

## Project principles

- Prove completion with executed checks and concrete evidence.
- Match planning depth to task size.
- Retry intelligently; change strategy after the same failure occurs twice.
- Ask when authority, safety, or a material product choice requires the user.
- Prefer built-in Codex subagents for bounded parallel work.
- Treat permissions, sandboxing, and repository instructions as hard constraints.

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md), and
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License and provenance

MIT. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).
