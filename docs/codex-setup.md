# Codex setup

## Recommended install target

Current official OpenAI documentation lists `~/.agents/skills` for user-scoped skills and
`$REPO_ROOT/.agents/skills` for repository-scoped skills.

```bash
# User scope
bash scripts/install-skills.sh --agents

# Current repository scope
bash scripts/install-skills.sh --repo --agents
```

PowerShell uses the same flags with `scripts/install-skills.ps1`.

Legacy `$CODEX_HOME/skills` and `.codex/skills` targets remain available for existing Vibe Codex
installations by omitting `--agents`. The canonical source stays in this repository's `skills`
directory for plugin packaging and installer compatibility.

Restart Codex if an updated skill does not appear.

## Skill activation

- Run `/skills` in Codex CLI or the IDE extension to use the picker.
- Type `$vc-router`, `$vc-phase-loop`, `$vc-agent-teams`, `$vcg`, or `$vcf` for explicit invocation.
- Codex may invoke non-alias skills implicitly when the request matches their descriptions.

## Optional OpenAI Developer Docs MCP

```bash
vc mcp docs
```

Equivalent direct command:

```bash
codex mcp add openaiDeveloperDocs --url https://developers.openai.com/mcp
```

The metadata files declare this MCP dependency so supported clients can surface it.

## Verify

```bash
bash scripts/doctor.sh --strict
node --test scripts/vc-teams.test.mjs
```

The doctor checks both current `.agents/skills` locations and legacy paths.

## Built-in subagents and `vc teams`

Use Codex built-in subagents for independent in-session work. Subagent activity is visible in Codex
clients, and `/agent` lets CLI users inspect or switch threads.

Use `vc teams` only when you need durable JSON messages that another process can inspect later. It is
a companion coordination utility and does not launch Codex agents.
