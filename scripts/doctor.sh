#!/usr/bin/env sh
set -eu

echo "Vibe Skills Doctor"

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

dest_root="${CODEX_HOME:-$HOME/.codex}"
skills_dir="$dest_root/skills"

echo "CODEX_HOME: $dest_root"

if [ -d "$skills_dir" ]; then
  count=$(find "$skills_dir" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
  echo "Skills dir: $skills_dir ($count installed)"
else
  echo "Skills dir not found: $skills_dir"
fi

if [ -d "$repo_root/.git" ]; then
  echo "Repo: $repo_root"
  git -C "$repo_root" rev-parse --abbrev-ref HEAD | awk '{print "Branch: " $0}'
  git -C "$repo_root" rev-parse --short HEAD | awk '{print "Commit: " $0}'
else
  repo_dir="${VIBE_SKILLS_HOME:-$HOME/.vibe-skills}"
  echo "Repo not found at: $repo_dir"
  echo "Tip: set VIBE_SKILLS_HOME or run the bootstrap one-liner."
fi

if [ -d "$skills_dir/vibe-router" ]; then
  echo "Core skill present: vibe-router"
else
  echo "Core skill missing: vibe-router"
fi

echo "Next: 끝까지: 원하는 목표를 적어줘 (예: 끝까지: 로그인페이지 만들어줘)"
echo "      or vibe go 로그인페이지 만들어줘 / vibe finish 로그인페이지 만들어줘"
