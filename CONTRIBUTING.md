# Contributing

Vibe Codex welcomes focused fixes, tests, documentation, and workflow research.

## Before opening a pull request

1. Open an issue for new commands, behavior changes, or new skills.
2. Keep `scripts/*.sh` and `scripts/*.ps1` behavior aligned.
3. Keep each `SKILL.md`, `agents/openai.yaml`, and compatibility `SKILL.json` description aligned.
4. Avoid absolute claims such as guaranteed success or infinite retries.
5. Add or update tests for executable behavior.
6. Run:

```bash
bash scripts/doctor.sh --strict
node --test scripts/vc-teams.test.mjs
```

Do not include credentials, private prompts, mailbox contents, or copied proprietary instructions.

