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
- Assume the user is non-technical; avoid long explanations and provide copy/paste steps when actions are required.

## Vibe Fast Path

- Assign Terminal A as Author and Terminal B as Reviewer.
- If using OpenCode, keep A on `build` and B on `plan`.
- Create a feature branch and push small commits early.
- Open a PR quickly; review and test on B; apply fixes on A; repeat.

## Vibe Quick Invoke

- `use git-dual-terminal-loop: start A/B workflow`
- `set up author/reviewer loop for this repo`

## Vibe Finish

If the user says "아무것도 모르겠다", "끝까지 해줘", "끝까지", "그냥해줘", "걍해줘", or "ㄱㄱ", auto-assign A/B roles, start the PR loop, and avoid mid-stream questions. Ask for approvals only after the first review pass.

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

## Performance Tips

- Keep A and B in separate worktrees to avoid branch churn.
- Use small commits (50-200 LOC) with one logical change each.
- Open PRs early to start review in parallel.
- Run a fast smoke test first, then expand if needed.
- Summarize findings in PR comments with actionable next steps.

## Tooling

- GitHub: use `gh` for PR create/view/diff/comment.
- GitLab: use `glab` with the same flow.
- Diff readability: use `delta` if installed; otherwise use `git diff` and `git log`.

## OpenCode Mapping

- Terminal A: OpenCode `build` agent for edits, commits, and pushes.
- Terminal B: OpenCode `plan` agent for read-only review, tests, and comments.
- Keep B read-only to avoid conflicting edits; route fixes to A.
- Use Tab to switch agents only if roles must temporarily change.

## Codex Role Prompts

Use these once per terminal to lock roles.

Terminal A (Author):
```text
Role: Terminal A (Author).
Rules: Only edit/commit/push. Assume defaults and record assumptions. Ask questions only at the end. Communicate via PR.
```

Terminal B (Reviewer):
```text
Role: Terminal B (Reviewer).
Rules: Do not edit code. Review diffs, run tests, and leave PR comments. Request changes from A.
```

Script shortcut:
- Mac/Linux: `bash scripts/role-prompts.sh author` and `bash scripts/role-prompts.sh reviewer`
- Windows: `.\scripts\role-prompts.ps1 author` and `.\scripts\role-prompts.ps1 reviewer`

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

Worktree setup (B):
```bash
git worktree add ../repo-review feature/<name>
cd ../repo-review
```

Fallback if no gh/glab:
- Use web UI to create and review PRs.
- Use `git show`, `git diff`, and `git log` locally for review.

Optional diff setup (delta):
```bash
git config --global pager.diff delta
git config --global pager.show delta
git config --global pager.log delta
git config --global delta.side-by-side true
```
