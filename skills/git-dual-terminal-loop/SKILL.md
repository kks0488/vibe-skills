---
name: git-dual-terminal-loop
description: Two-terminal workflow for vibe coding using Git as the single source of truth. Use when the user wants parallel author and reviewer roles, PR-based communication, rapid review loops, or asks about gh/glab, delta, or two-terminal setup.
---

# Dual Terminal Git Loop

## Vibe Defaults

- Prefer fast iteration and shipping a working baseline over perfection.
- Make safe default choices without pausing; record assumptions briefly.
- Ask questions only after delivering an initial result, unless the workflow requires confirmation for safety/legal reasons.
- Keep outputs concise, actionable, and easy to extend.

## Vibe Fast Path

- Assign Terminal A as Author and Terminal B as Reviewer.
- Create a feature branch and push small commits early.
- Open a PR quickly; review and test on B; apply fixes on A; repeat.

## Principles

- Use Git as the single source of truth for diffs, history, and attribution.
- Prefer review via PRs and line comments over out-of-band notes.
- Keep authorship clear: only A edits code; B reviews and tests.

## Roles

- Terminal A (Author): edit files, commit in small units, push, update PR, resolve feedback.
- Terminal B (Reviewer): fetch and review diffs, run tests, leave line comments, summarize findings.

## Workflow

1. Create a feature branch on A.
2. Implement in small, reviewable commits.
3. Push and open a PR early.
4. Review on B using PR diff or `git diff`; leave line comments.
5. Run tests on B; record results in PR comments.
6. Apply feedback on A with new commits and push.
7. Repeat until approved; merge from A.

## Tooling

- GitHub: use `gh` for PR create/view/diff/comment.
- GitLab: use `glab` with the same flow.
- Diff readability: use `delta` if installed; otherwise use `git diff` and `git log`.

## Command Sketch

Author (A):
```bash
git checkout -b feature/<name>
git add -A
git commit -m "feat: <small change>"
git push -u origin feature/<name>
gh pr create
```

Reviewer (B):
```bash
git fetch origin
git checkout feature/<name>
gh pr view
gh pr diff
# run tests, then comment in PR
```

Fallback if no gh/glab:
- Use web UI to create and review PRs.
- Use `git show`, `git diff`, and `git log` locally for review.
