# Codex compatibility checklist

Last documentation review: 2026-08-14.

Before each Vibe Codex release:

1. Check the official [Build skills](https://learn.chatgpt.com/docs/build-skills) page for skill
   structure, discovery locations, metadata, and invocation changes.
2. Check the official [Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents) page
   before changing delegation guidance.
3. Run `codex --version` and record the locally exercised version in release notes.
4. Run shell and PowerShell doctor workflows in CI.
5. Run `node --test scripts/vc-teams.test.mjs`.
6. Confirm every `SKILL.md` name and description matches its `agents/openai.yaml` and compatibility
   `SKILL.json` files.
7. Check that backups are outside active skill roots, because recursive discovery can load duplicate
   skill names.
8. Avoid claims that a project feature is Codex-native unless the official documentation describes
   that feature.

Compatibility notes should say what was actually tested. Do not promise unlimited retries,
guaranteed success, or support for untested clients.
