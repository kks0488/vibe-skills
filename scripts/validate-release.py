#!/usr/bin/env python3
"""Validate release metadata without third-party dependencies."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
ERRORS: list[str] = []


def fail(message: str) -> None:
    ERRORS.append(message)


def frontmatter(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        fail(f"missing YAML frontmatter: {path.relative_to(ROOT)}")
        return {}
    data: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if line.startswith("  ") or ":" not in line:
            continue
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip()
    return data


version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
readme = (ROOT / "README.md").read_text(encoding="utf-8")
if not re.fullmatch(r"v\d+\.\d+\.\d+", version):
    fail(f"invalid VERSION: {version!r}")
if version not in readme:
    fail(f"README does not mention current version {version}")
if not (ROOT / "LICENSE").is_file():
    fail("LICENSE is missing")

plugin_manifest_path = ROOT / ".codex-plugin" / "plugin.json"
if not plugin_manifest_path.is_file():
    fail("Codex plugin manifest is missing")
else:
    try:
        plugin_manifest = json.loads(plugin_manifest_path.read_text(encoding="utf-8"))
        if plugin_manifest.get("name") != "vibe-codex":
            fail("plugin name must be vibe-codex")
        if f"v{plugin_manifest.get('version')}" != version:
            fail("plugin version differs from VERSION")
        if plugin_manifest.get("skills") != "./skills/":
            fail("plugin skills path differs from the canonical source tree")
    except json.JSONDecodeError as exc:
        fail(f"invalid plugin manifest JSON: {exc}")

obsolete = [
    ROOT / "THIRD_PARTY_NOTICES.md",
    ROOT / "spec" / "agent-skills-spec.md",
    ROOT / ".claude-plugin" / "marketplace.json",
]
for path in obsolete:
    if path.exists():
        fail(f"obsolete inherited file still present: {path.relative_to(ROOT)}")

core_names = {
    line.strip()
    for line in (ROOT / "scripts" / "core-skills.txt").read_text(encoding="utf-8").splitlines()
    if line.strip() and not line.lstrip().startswith("#")
}
directory_names = {path.name for path in SKILLS.iterdir() if path.is_dir()}
if core_names != directory_names:
    fail(f"core skill list differs from directories: list={sorted(core_names)} dirs={sorted(directory_names)}")

prohibited = ("infinite retry", "never fail", "never ask")
for skill_dir in sorted(path for path in SKILLS.iterdir() if path.is_dir()):
    skill_md = skill_dir / "SKILL.md"
    legacy_json = skill_dir / "SKILL.json"
    openai_yaml = skill_dir / "agents" / "openai.yaml"
    for required in (skill_md, legacy_json, openai_yaml):
        if not required.is_file():
            fail(f"missing skill file: {required.relative_to(ROOT)}")
    if not all(path.is_file() for path in (skill_md, legacy_json, openai_yaml)):
        continue

    meta = frontmatter(skill_md)
    if meta.get("name") != skill_dir.name:
        fail(f"skill name mismatch in {skill_md.relative_to(ROOT)}")
    description = meta.get("description", "")
    if not description or len(description) > 1024:
        fail(f"invalid description in {skill_md.relative_to(ROOT)}")

    try:
        legacy = json.loads(legacy_json.read_text(encoding="utf-8"))
        current = json.loads(openai_yaml.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON-formatted metadata for {skill_dir.name}: {exc}")
        continue
    if legacy != current:
        fail(f"SKILL.json and agents/openai.yaml differ for {skill_dir.name}")

    lowered = skill_md.read_text(encoding="utf-8").lower()
    for phrase in prohibited:
        if phrase in lowered:
            fail(f"prohibited absolute claim {phrase!r} in {skill_md.relative_to(ROOT)}")

if ERRORS:
    for error in ERRORS:
        print(f"ERROR: {error}", file=sys.stderr)
    raise SystemExit(1)

print(f"release metadata OK: {version}, {len(directory_names)} skills")
