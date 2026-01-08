#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
src_dir="$repo_root/skills"

dest_root="${CODEX_HOME:-$HOME/.codex}"
dest_dir="$dest_root/skills"

if [ ! -d "$dest_dir" ]; then
  echo "Skills dir not found: $dest_dir"
  exit 1
fi

timestamp=$(date +"%Y%m%d%H%M%S")
backup_dir="$dest_root/skills.bak-$timestamp"
mkdir -p "$backup_dir"

removed=0
for skill in "$src_dir"/*; do
  [ -d "$skill" ] || continue
  name=$(basename "$skill")
  dest="$dest_dir/$name"
  if [ -e "$dest" ]; then
    mv "$dest" "$backup_dir/"
    removed=$((removed + 1))
  fi
done

echo "Removed $removed skill(s)."
echo "Backup dir: $backup_dir"
