#!/usr/bin/env sh
set -eu

strict="false"
case "${VC_DOCTOR_STRICT:-}" in
  1|true|TRUE|yes|YES) strict="true" ;;
esac

while [ "$#" -gt 0 ]; do
  case "$1" in
    --strict)
      strict="true"
      ;;
    -h|--help)
      cat <<'EOF'
Usage: doctor.sh [--strict]

  --strict  Exit non-zero if skill metadata validation fails.

Env:
  VC_DOCTOR_STRICT=1  Same as --strict
EOF
      exit 0
      ;;
    *)
      echo "WARN: unknown arg (ignored): $1" >&2
      ;;
  esac
  shift
done

echo "VC Skills Doctor"

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
skills_repo_root=$(cd "$script_dir/.." && pwd)

user_root="${CODEX_HOME:-$HOME/.codex}"
user_skills_dir="$user_root/skills"
user_agents_skills_dir="$HOME/.agents/skills"

cwd=$(pwd)
cwd_skills_dir="$cwd/.codex/skills"
cwd_agents_skills_dir="$cwd/.agents/skills"
repo_root=""
repo_skills_dir=""
repo_agents_skills_dir=""
source_skills_dir="$skills_repo_root/skills"

if command -v git >/dev/null 2>&1; then
  if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    repo_root=$(git -C "$cwd" rev-parse --show-toplevel)
    repo_root=$(printf "%s" "$repo_root" | tr -d '\r')
    repo_skills_dir="$repo_root/.codex/skills"
    repo_agents_skills_dir="$repo_root/.agents/skills"
  fi
fi

echo "CODEX_HOME: $user_root"
if command -v codex >/dev/null 2>&1; then
  codex_path=$(command -v codex)
  codex_version=$(codex --version 2>/dev/null | tr -d '\r' || true)
  if [ -n "$codex_version" ]; then
    echo "codex: $codex_version ($codex_path)"
  fi
fi

config_file="$user_root/config.toml"
if [ -f "$config_file" ]; then
  if grep -q '^\[mcp_servers\.openaiDeveloperDocs\]' "$config_file" 2>/dev/null && grep -q 'developers\.openai\.com/mcp' "$config_file" 2>/dev/null; then
    echo "OpenAI Docs MCP: configured (openaiDeveloperDocs)"
  else
    echo "OpenAI Docs MCP: not configured (openaiDeveloperDocs)"
    echo "Tip: vc mcp docs  (or: codex mcp add openaiDeveloperDocs --url https://developers.openai.com/mcp)"
  fi
else
  echo "Config not found: $config_file"
  echo "Tip: vc mcp docs  (or: codex mcp add openaiDeveloperDocs --url https://developers.openai.com/mcp)"
fi

count_dirs() {
  # Count skills by looking for <skill-dir>/SKILL.md (Codex scans SKILL.md files, not directories).
  find "$1" -maxdepth 2 -mindepth 2 -type f -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' '
}

total_skill_issues=0

looks_like_json() {
  f="$1"
  if [ ! -f "$f" ]; then
    return 1
  fi
  first_char=$(
    awk '{
      gsub("\r", "");
      sub(/^[ \t]+/, "", $0);
      if ($0 == "" || $0 ~ /^#/) next;
      print substr($0, 1, 1);
      exit
    }' "$f" 2>/dev/null || true
  )
  [ "$first_char" = "{" ] || [ "$first_char" = "[" ]
}

validate_skill_metadata_json_file() {
  metadata_path="$1"
  if [ ! -f "$metadata_path" ]; then
    return 0
  fi

  # Codex skill metadata is YAML at `agents/openai.yaml`, but JSON is a YAML subset.
  # We validate JSON-formatted files; non-JSON YAML is skipped (Codex itself is fail-open on metadata).
  case "$metadata_path" in
    *.yaml|*.yml)
      if ! looks_like_json "$metadata_path"; then
        return 0
      fi
      ;;
  esac

  if command -v python3 >/dev/null 2>&1; then
    if ! python3 - "$metadata_path" <<'PY'
import json
import re
import sys

path = sys.argv[1]

MAX_NAME = 64
MAX_DESC = 1024

def sanitize_single_line(value: str) -> str:
    return " ".join(value.split())

def err(msg: str) -> None:
    print(f"WARN: {msg}: {path}")

def check_len(field: str, value: object, max_len: int) -> bool:
    if value is None:
        return True
    if not isinstance(value, str):
        err(f"invalid {field} (expected string)")
        return False
    v = sanitize_single_line(value)
    if not v:
        err(f"invalid {field} (empty)")
        return False
    if len(v) > max_len:
        err(f"invalid {field} (exceeds {max_len} chars)")
        return False
    return True

ok = True
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception as e:
    err(f"invalid metadata JSON ({e})")
    sys.exit(1)

interface = data.get("interface") or {}
if not isinstance(interface, dict):
    err("invalid interface (expected object)")
    ok = False
else:
    ok = check_len("interface.display_name", interface.get("display_name"), MAX_NAME) and ok
    ok = check_len("interface.short_description", interface.get("short_description"), MAX_DESC) and ok
    ok = check_len("interface.default_prompt", interface.get("default_prompt"), MAX_DESC) and ok
    brand = interface.get("brand_color")
    if brand is not None:
        if not isinstance(brand, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", brand.strip()):
            err(f"invalid interface.brand_color (expected #RRGGBB, got {brand!r})")
            ok = False

deps = data.get("dependencies") or {}
if deps is not None:
    if not isinstance(deps, dict):
        err("invalid dependencies (expected object)")
        ok = False
    else:
        tools = deps.get("tools") or []
        if not isinstance(tools, list):
            err("invalid dependencies.tools (expected array)")
            ok = False
        else:
            for i, tool in enumerate(tools):
                if not isinstance(tool, dict):
                    err(f"invalid dependencies.tools[{i}] (expected object)")
                    ok = False
                    continue
                typ = tool.get("type")
                val = tool.get("value")
                if not (isinstance(typ, str) and sanitize_single_line(typ) and len(sanitize_single_line(typ)) <= MAX_NAME):
                    err(f"invalid dependencies.tools[{i}].type")
                    ok = False
                if not (isinstance(val, str) and sanitize_single_line(val) and len(sanitize_single_line(val)) <= MAX_DESC):
                    err(f"invalid dependencies.tools[{i}].value")
                    ok = False
                desc = tool.get("description")
                if desc is not None and not (isinstance(desc, str) and len(sanitize_single_line(desc)) <= MAX_DESC):
                    err(f"invalid dependencies.tools[{i}].description")
                    ok = False
                transport = tool.get("transport")
                if transport is not None and not (isinstance(transport, str) and len(sanitize_single_line(transport)) <= MAX_NAME):
                    err(f"invalid dependencies.tools[{i}].transport")
                    ok = False
                cmd = tool.get("command")
                if cmd is not None and not (isinstance(cmd, str) and len(sanitize_single_line(cmd)) <= MAX_DESC):
                    err(f"invalid dependencies.tools[{i}].command")
                    ok = False
                url = tool.get("url")
                if url is not None and not (isinstance(url, str) and len(sanitize_single_line(url)) <= MAX_DESC):
                    err(f"invalid dependencies.tools[{i}].url")
                    ok = False

                # Basic MCP dependency sanity (matches codex-rs/core/src/mcp/skill_dependencies.rs expectations).
                if isinstance(typ, str) and sanitize_single_line(typ).lower() == "mcp":
                    transport_value = sanitize_single_line(transport).lower() if isinstance(transport, str) else "streamable_http"
                    if transport_value == "streamable_http":
                        if not (isinstance(url, str) and sanitize_single_line(url)):
                            err(f"invalid dependencies.tools[{i}] (mcp streamable_http requires url)")
                            ok = False
                    elif transport_value == "stdio":
                        if not (isinstance(cmd, str) and sanitize_single_line(cmd)):
                            err(f"invalid dependencies.tools[{i}] (mcp stdio requires command)")
                            ok = False
                    else:
                        err(f"invalid dependencies.tools[{i}] (mcp unsupported transport {transport!r})")
                        ok = False

sys.exit(0 if ok else 1)
PY
    then
      return 1
    fi
  else
    echo "Note: python3 not found; skipping metadata validation: $metadata_path"
  fi

  return 0
}

validate_skill() {
  skill_dir="$1"
  skill_file="$skill_dir/SKILL.md"
  skill_json="$skill_dir/SKILL.json"
  skill_openai_yaml="$skill_dir/agents/openai.yaml"
  if [ ! -f "$skill_file" ]; then
    echo "WARN: missing SKILL.md: $skill_dir"
    return 1
  fi

  first_line=$(sed -n '1p' "$skill_file" | tr -d '\r')
  if [ "$first_line" != "---" ]; then
    echo "WARN: missing frontmatter: $skill_file"
    return 1
  fi

  frontmatter=$(awk 'NR==1{next} {gsub("\r", ""); if ($0=="---") {exit} print}' "$skill_file")
  name=$(printf "%s\n" "$frontmatter" | awk -F':' '$1 ~ /^[[:space:]]*name[[:space:]]*$/ { $1=""; sub(/^:/, "", $0); sub(/^[[:space:]]+/, "", $0); print; exit }')
  desc=$(printf "%s\n" "$frontmatter" | awk -F':' '$1 ~ /^[[:space:]]*description[[:space:]]*$/ { $1=""; sub(/^:/, "", $0); sub(/^[[:space:]]+/, "", $0); print; exit }')
  short_desc=$(printf "%s\n" "$frontmatter" | awk -F':' '$1 ~ /^[[:space:]]*short-description[[:space:]]*$/ { $1=""; sub(/^:/, "", $0); sub(/^[[:space:]]+/, "", $0); print; exit }')

  if [ -z "$name" ]; then
    echo "WARN: missing name: $skill_file"
    return 1
  fi
  if [ -z "$desc" ]; then
    echo "WARN: missing description: $skill_file"
    return 1
  fi

  skill_basename=$(basename "$skill_dir")
  name_clean=$(printf "%s" "$name" | sed 's/^"//; s/"$//' | sed "s/^'//; s/'$//" | sed 's/[[:space:]]*$//')
  if [ "$skill_basename" != "$name_clean" ]; then
    echo "WARN: skill dir name mismatch (dir=$skill_basename, frontmatter name=$name_clean): $skill_file"
    return 1
  fi

  name_len=$(printf "%s" "$name" | wc -m | tr -d ' ')
  desc_len=$(printf "%s" "$desc" | wc -m | tr -d ' ')
  short_desc_len=$(printf "%s" "$short_desc" | wc -m | tr -d ' ')

  # Match Codex CLI constraints (codex-rs/core/src/skills/loader.rs).
  if [ "$name_len" -gt 64 ]; then
    echo "WARN: name too long ($name_len > 64): $skill_file"
    return 1
  fi
  if [ "$desc_len" -gt 1024 ]; then
    echo "WARN: description too long ($desc_len > 1024): $skill_file"
    return 1
  fi
  if [ -n "$short_desc" ] && [ "$short_desc_len" -gt 1024 ]; then
    echo "WARN: metadata.short-description too long ($short_desc_len > 1024): $skill_file"
    return 1
  fi

  if ! validate_skill_metadata_json_file "$skill_openai_yaml"; then
    return 1
  fi

  if [ -f "$skill_json" ]; then
    if ! validate_skill_metadata_json_file "$skill_json"; then
      return 1
    fi
  fi

  if [ -f "$skill_openai_yaml" ] && looks_like_json "$skill_openai_yaml" && [ -f "$skill_json" ] && command -v python3 >/dev/null 2>&1; then
    if ! python3 - "$skill_openai_yaml" "$skill_json" <<'PY'
import json
import sys

path_yaml = sys.argv[1]
path_json = sys.argv[2]

def load(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def normalize(obj: dict) -> dict:
    interface = obj.get("interface") or {}
    deps = obj.get("dependencies") or {}
    tools = deps.get("tools") or []
    tools_norm = []
    if isinstance(tools, list):
        for t in tools:
            if isinstance(t, dict):
                tools_norm.append({k: t.get(k) for k in ["type", "value", "description", "transport", "command", "url"] if k in t})
    tools_norm.sort(key=lambda t: (t.get("type") or "", t.get("value") or "", t.get("transport") or "", t.get("url") or "", t.get("command") or "", t.get("description") or ""))
    return {
        "interface": {k: interface.get(k) for k in ["display_name", "short_description", "brand_color", "default_prompt"] if k in interface},
        "dependencies": {"tools": tools_norm},
    }

try:
    a = normalize(load(path_yaml))
    b = normalize(load(path_json))
except Exception as e:
    print(f"WARN: failed to compare metadata ({e}): {path_yaml} vs {path_json}")
    sys.exit(1)

if a != b:
    print(f"WARN: metadata mismatch between agents/openai.yaml and SKILL.json: {path_yaml} vs {path_json}")
    sys.exit(1)

sys.exit(0)
PY
    then
      return 1
    fi
  fi

  return 0
}

validate_skills_dir() {
  dir="$1"
  label="$2"
  if [ ! -d "$dir" ]; then
    return 0
  fi

  echo "Checking skill metadata ($label): $dir"
  dir_issues=0
  dir_skipped=0
  for skill in "$dir"/*; do
    [ -d "$skill" ] || continue
    if [ ! -f "$skill/SKILL.md" ]; then
      dir_skipped=$((dir_skipped + 1))
      continue
    fi
    if ! validate_skill "$skill"; then
      dir_issues=$((dir_issues + 1))
    fi
  done

  total_skill_issues=$((total_skill_issues + dir_issues))

  if [ "$dir_issues" -eq 0 ]; then
    echo "Skill metadata OK ($label)"
  else
    echo "Skill metadata issues: $dir_issues ($label)"
  fi
  if [ "$dir_skipped" -ne 0 ]; then
    echo "Skipped non-skill dirs (no SKILL.md): $dir_skipped ($label)"
  fi
}

if [ -d "$user_agents_skills_dir" ]; then
  count=$(count_dirs "$user_agents_skills_dir")
  echo "Skills dir (user, .agents): $user_agents_skills_dir ($count installed)"
  legacy_backups=$(find "$user_agents_skills_dir" -maxdepth 1 -mindepth 1 -type d -name "*.bak-*" -exec basename {} \; 2>/dev/null | tr '\n' ' ' | sed 's/ $//')
  if [ -n "$legacy_backups" ]; then
    echo "WARN: legacy backup skill folders detected (will load as duplicate skills): $legacy_backups"
    echo "Tip: move them out of $user_agents_skills_dir (e.g. $HOME/.agents/skills.bak-<timestamp>) or delete them."
  fi
else
  echo "Skills dir not found: $user_agents_skills_dir"
fi

if [ -d "$user_skills_dir" ]; then
  count=$(count_dirs "$user_skills_dir")
  echo "Skills dir (user, legacy): $user_skills_dir ($count installed)"
  legacy_backups=$(find "$user_skills_dir" -maxdepth 1 -mindepth 1 -type d -name "*.bak-*" -exec basename {} \; 2>/dev/null | tr '\n' ' ' | sed 's/ $//')
  if [ -n "$legacy_backups" ]; then
    echo "WARN: legacy backup skill folders detected (will load as duplicate skills): $legacy_backups"
    echo "Tip: move them out of $user_skills_dir (e.g. $user_root/skills.bak-<timestamp>) or delete them."
  fi
else
  echo "Skills dir not found: $user_skills_dir"
fi

if [ -d "$cwd_skills_dir" ]; then
  count=$(count_dirs "$cwd_skills_dir")
  echo "Skills dir (repo cwd): $cwd_skills_dir ($count installed)"
fi
if [ -d "$cwd_agents_skills_dir" ]; then
  count=$(count_dirs "$cwd_agents_skills_dir")
  echo "Skills dir (repo cwd, .agents): $cwd_agents_skills_dir ($count installed)"
fi

if [ -n "$repo_skills_dir" ] && [ "$repo_skills_dir" != "$cwd_skills_dir" ] && [ -d "$repo_skills_dir" ]; then
  count=$(count_dirs "$repo_skills_dir")
  echo "Skills dir (repo root): $repo_skills_dir ($count installed)"
fi
if [ -n "$repo_agents_skills_dir" ] && [ "$repo_agents_skills_dir" != "$cwd_agents_skills_dir" ] && [ -d "$repo_agents_skills_dir" ]; then
  count=$(count_dirs "$repo_agents_skills_dir")
  echo "Skills dir (repo root, .agents): $repo_agents_skills_dir ($count installed)"
fi

if [ -d "$skills_repo_root/.git" ]; then
  echo "Repo: $skills_repo_root"
  git -C "$skills_repo_root" rev-parse --abbrev-ref HEAD | awk '{print "Branch: " $0}'
  git -C "$skills_repo_root" rev-parse --short HEAD | awk '{print "Commit: " $0}'
  version_file="$skills_repo_root/VERSION"
  if [ -f "$version_file" ]; then
    version=$(tr -d ' \t\r\n' < "$version_file")
    if [ -n "$version" ]; then
      echo "Version: $version"
    fi
  fi
else
  repo_dir="${VC_SKILLS_HOME:-${VS_SKILLS_HOME:-${VIBE_SKILLS_HOME:-$HOME/.vc-skills}}}"
  echo "Repo not found at: $repo_dir"
  echo "Tip: set VC_SKILLS_HOME (or legacy VS_SKILLS_HOME/VIBE_SKILLS_HOME) or run the bootstrap one-liner."
fi

core_skill=""
if [ -d "$user_agents_skills_dir/vc-router" ]; then
  core_skill="$user_agents_skills_dir"
elif [ -d "$user_skills_dir/vc-router" ]; then
  core_skill="$user_skills_dir"
elif [ -d "$cwd_skills_dir/vc-router" ]; then
  core_skill="$cwd_skills_dir"
elif [ -d "$cwd_agents_skills_dir/vc-router" ]; then
  core_skill="$cwd_agents_skills_dir"
elif [ -n "$repo_skills_dir" ] && [ -d "$repo_skills_dir/vc-router" ]; then
  core_skill="$repo_skills_dir"
elif [ -n "$repo_agents_skills_dir" ] && [ -d "$repo_agents_skills_dir/vc-router" ]; then
  core_skill="$repo_agents_skills_dir"
elif [ -d "$source_skills_dir/vc-router" ]; then
  core_skill="$source_skills_dir"
fi

if [ -n "$core_skill" ]; then
  echo "Core skill present: vc-router ($core_skill)"
else
  echo "Core skill missing: vc-router"
fi

validate_skills_dir "$user_agents_skills_dir" "user-agents"
validate_skills_dir "$user_skills_dir" "user-legacy"
validate_skills_dir "$cwd_skills_dir" "repo-cwd"
validate_skills_dir "$cwd_agents_skills_dir" "repo-cwd-agents"
validate_skills_dir "$source_skills_dir" "source"
if [ -n "$repo_skills_dir" ] && [ "$repo_skills_dir" != "$cwd_skills_dir" ]; then
  validate_skills_dir "$repo_skills_dir" "repo-root"
fi
if [ -n "$repo_agents_skills_dir" ] && [ "$repo_agents_skills_dir" != "$cwd_agents_skills_dir" ]; then
  validate_skills_dir "$repo_agents_skills_dir" "repo-root-agents"
fi

echo "Next: copy/paste into Codex chat:"
legacy_skills=$(
  {
    find "$user_skills_dir" -maxdepth 1 -mindepth 1 -type d \( -name "vibe-*" -o -name "vs-*" -o -name "vf" -o -name "vg" -o -name "vsf" -o -name "vsg" \) -exec basename {} \; 2>/dev/null || true
    find "$user_agents_skills_dir" -maxdepth 1 -mindepth 1 -type d \( -name "vibe-*" -o -name "vs-*" -o -name "vf" -o -name "vg" -o -name "vsf" -o -name "vsg" \) -exec basename {} \; 2>/dev/null || true
  } | sort -u
)
legacy_skills=$(printf "%s\n" "$legacy_skills" | tr '\n' ' ' | sed 's/ $//')
if [ -n "$legacy_skills" ]; then
  echo "Warning: legacy vibe/vs skills detected: $legacy_skills"
  echo "Tip: remove or rename legacy skills to avoid conflicts."
fi
echo '$vcg build a login page'
echo 'Tip: use "$vcf ..." for end-to-end execution with verification.'

if [ "$strict" = "true" ] && [ "$total_skill_issues" -ne 0 ]; then
  echo "ERROR: skill metadata issues detected: $total_skill_issues" >&2
  exit 1
fi
