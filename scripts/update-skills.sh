#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

cd "$repo_root"
git pull --ff-only
bash "$repo_root/scripts/install-skills.sh"
