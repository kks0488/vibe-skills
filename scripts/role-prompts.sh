#!/usr/bin/env sh
set -eu

case "${1:-all}" in
  author|a)
    cat <<'EOF'
Role: Terminal A (Author).
Rules: Only edit/commit/push. Assume defaults and record assumptions. Ask questions only at the end. Communicate via PR.
EOF
    ;;
  reviewer|review|r)
    cat <<'EOF'
Role: Terminal B (Reviewer).
Rules: Do not edit code. Review diffs, run tests, and leave PR comments. Request changes from A.
EOF
    ;;
  all)
    cat <<'EOF'
Terminal A (Author):
Role: Terminal A (Author).
Rules: Only edit/commit/push. Assume defaults and record assumptions. Ask questions only at the end. Communicate via PR.

Terminal B (Reviewer):
Role: Terminal B (Reviewer).
Rules: Do not edit code. Review diffs, run tests, and leave PR comments. Request changes from A.
EOF
    ;;
  *)
    echo "Usage: role-prompts.sh [author|reviewer|all]" >&2
    exit 1
    ;;
esac
