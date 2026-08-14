#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
skills_repo_root=$(cd "$script_dir/.." && pwd)
src_dir="$skills_repo_root/skills"
core_skills_file="$script_dir/core-skills.txt"

usage() {
  cat <<'EOF'
Usage: install-skills.sh [--user|--repo|--path <dir>] [--agents]

  --core        (legacy) No-op. This repo ships only vc skills.
  --all         (legacy) No-op. This repo ships only vc skills.
  --user        Install to user skills scope (default)
                - default: $CODEX_HOME/skills (legacy-compatible)
                - with --agents: ~/.agents/skills (Codex docs default)
  --repo        Install to repo skills scope (from current directory)
                - default: <git-root>/.codex/skills
                - with --agents: <git-root>/.agents/skills
  --path <dir>  Install to an explicit skills directory
  --agents      Use .agents/skills locations for --user/--repo
EOF
}

read_core_skills() {
  if [ ! -f "$core_skills_file" ]; then
    echo "Error: missing core skills list: $core_skills_file" >&2
    exit 1
  fi
  awk 'NF && $1 !~ /^#/' "$core_skills_file"
}

scope="user"
custom_dest=""
use_agents="false"
legacy_all="false"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --core)
      :
      ;;
    --all)
      legacy_all="true"
      ;;
    --user)
      scope="user"
      ;;
    --repo)
      scope="repo"
      ;;
    --agents)
      use_agents="true"
      ;;
    --path)
      shift
      if [ -z "${1:-}" ]; then
        echo "Error: --path requires a directory." >&2
        usage >&2
        exit 1
      fi
      custom_dest="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ -n "$custom_dest" ]; then
  dest_dir="$custom_dest"
elif [ "$scope" = "repo" ]; then
  if command -v git >/dev/null 2>&1 && git -C "$PWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    repo_root=$(git -C "$PWD" rev-parse --show-toplevel)
    if [ "$use_agents" = "true" ]; then
      dest_dir="$repo_root/.agents/skills"
    else
      dest_dir="$repo_root/.codex/skills"
    fi
  else
    echo "Error: not inside a git repo. Use --path or run inside a repo." >&2
    exit 1
  fi
else
  if [ "$use_agents" = "true" ]; then
    dest_dir="$HOME/.agents/skills"
  else
    dest_root="${CODEX_HOME:-$HOME/.codex}"
    dest_dir="$dest_root/skills"
  fi
fi

mkdir -p "$dest_dir"

timestamp=$(date +"%Y%m%d%H%M%S")
backup_dir=""
if [ "$legacy_all" = "true" ]; then
  echo "Note: --all is deprecated; this repo ships only vc skills." >&2
fi

for name in $(read_core_skills); do
  skill="$src_dir/$name"
  if [ ! -d "$skill" ]; then
    echo "WARN: core skill missing in repo (skipping): $name" >&2
    continue
  fi
  dest="$dest_dir/$name"
  if [ -e "$dest" ]; then
    if [ -z "$backup_dir" ]; then
      backup_dir="$(dirname "$dest_dir")/skills.bak-$timestamp"
      mkdir -p "$backup_dir"
    fi
    mv "$dest" "$backup_dir/$name"
  fi
  cp -R "$skill" "$dest"
done

echo "Installed skills to $dest_dir"
if [ -n "$backup_dir" ]; then
  echo "Backup dir: $backup_dir"
fi
echo "Next: copy/paste into Codex chat:"
legacy_skills=$(find "$dest_dir" -maxdepth 1 -mindepth 1 -type d \( -name "vibe-*" -o -name "vs-*" -o -name "vf" -o -name "vg" -o -name "vsf" -o -name "vsg" \) -exec basename {} \; | tr '\n' ' ' | sed 's/ $//')
if [ -n "$legacy_skills" ]; then
  echo "Warning: legacy vibe/vs skills detected: $legacy_skills"
  echo "Tip: remove or rename legacy skills to avoid conflicts."
fi
echo '$vcg build a login page'
echo 'Tip: use "$vcf ..." for end-to-end execution with verification.'
echo "Tip: vc mcp docs  (install OpenAI developer docs MCP server)."
