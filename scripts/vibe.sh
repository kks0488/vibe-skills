#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

cmd="${1:-help}"
shift 2>/dev/null || true

case "$cmd" in
  install)
    sh "$repo_root/scripts/install-skills.sh"
    ;;
  update)
    sh "$repo_root/scripts/update-skills.sh"
    ;;
  doctor)
    sh "$repo_root/scripts/doctor.sh"
    ;;
  list)
    sh "$repo_root/scripts/list-skills.sh"
    ;;
  uninstall)
    sh "$repo_root/scripts/uninstall-skills.sh"
    ;;
  prompts)
    sh "$repo_root/scripts/role-prompts.sh" "${1:-all}"
    ;;
  go|finish)
    if [ -z "${1:-}" ]; then
      echo "Usage: vibe go <goal>  (or vibe finish <goal>)" >&2
      echo "Example: vibe go 로그인페이지 만들어줘" >&2
      exit 1
    fi
    echo "끝까지: $*"
    ;;
  sync)
    if [ "$#" -lt 1 ]; then
      echo "Usage: vibe sync <host> [host...]" >&2
      exit 1
    fi
    sh "$repo_root/scripts/update-skills.sh"
    for host in "$@"; do
      echo "Updating $host"
      ssh "$host" 'curl -fsSL https://raw.githubusercontent.com/kks0488/vibe-skills/main/bootstrap.sh | bash'
    done
    ;;
  help|*)
    cat <<'EOF'
vibe commands:
  install    install skills into ~/.codex/skills
  update     pull repo + reinstall skills
  doctor     check install status
  list       list installed skills
  uninstall  remove skills (backup)
  prompts    print author/reviewer prompts
  go         print a short finish-to-end prompt
  finish     alias for go
  sync       update local + remote host(s)
EOF
    ;;
esac
