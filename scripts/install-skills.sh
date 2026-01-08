#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
src_dir="$repo_root/skills"

dest_root="${CODEX_HOME:-$HOME/.codex}"
dest_dir="$dest_root/skills"

mkdir -p "$dest_dir"

timestamp=$(date +"%Y%m%d%H%M%S")
for skill in "$src_dir"/*; do
  [ -d "$skill" ] || continue
  name=$(basename "$skill")
  dest="$dest_dir/$name"
  if [ -e "$dest" ]; then
    mv "$dest" "$dest.bak-$timestamp"
  fi
  cp -R "$skill" "$dest"
done

echo "Installed skills to $dest_dir"
echo "Backup suffix (if any): .bak-$timestamp"
echo "Next: 끝까지: <goal>  (or vibe go \"<goal>\")"
