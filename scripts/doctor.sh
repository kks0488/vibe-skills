#!/usr/bin/env sh
set -eu

echo "Vibe Skills Doctor"

dest_root="${CODEX_HOME:-$HOME/.codex}"
skills_dir="$dest_root/skills"

echo "CODEX_HOME: $dest_root"

if [ -d "$skills_dir" ]; then
  count=$(find "$skills_dir" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
  echo "Skills dir: $skills_dir ($count installed)"
else
  echo "Skills dir not found: $skills_dir"
fi

repo_dir="${VIBE_SKILLS_HOME:-$HOME/.vibe-skills}"
if [ -d "$repo_dir/.git" ]; then
  echo "Repo: $repo_dir"
  git -C "$repo_dir" rev-parse --abbrev-ref HEAD | awk '{print "Branch: " $0}'
  git -C "$repo_dir" rev-parse --short HEAD | awk '{print "Commit: " $0}'
else
  echo "Repo not found at: $repo_dir"
  echo "Tip: set VIBE_SKILLS_HOME or run the bootstrap one-liner."
fi

if [ -d "$skills_dir/vibe-router" ]; then
  echo "Core skill present: vibe-router"
else
  echo "Core skill missing: vibe-router"
fi

echo "Next: use vibe-router: <goal>"
