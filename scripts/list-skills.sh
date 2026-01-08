#!/usr/bin/env sh
set -eu

dest_root="${CODEX_HOME:-$HOME/.codex}"
skills_dir="$dest_root/skills"

if [ ! -d "$skills_dir" ]; then
  echo "Skills dir not found: $skills_dir"
  exit 1
fi

find "$skills_dir" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort
