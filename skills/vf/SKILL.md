---
name: vf
description: Short, explicit alias for vibe-phase-loop. Use only when the user explicitly invokes `use vf:` and wants the shortest reliable end-to-end plan/execute/test command.
---

# VF (Vibe Finish Alias)

## Vibe Defaults

- Prefer fast iteration and shipping a working baseline over perfection.
- Make safe default choices without pausing; record assumptions briefly.
- Ask questions only after delivering an initial result, unless the workflow requires confirmation for safety/legal reasons.
- Keep outputs concise, actionable, and easy to extend.
- Assume the user is non-technical; avoid long explanations and provide copy/paste steps when actions are required.
- If no explicit goal is provided, ask a single clarifying question before planning; do not infer by scanning the filesystem.
- Treat non-explicit triggers (e.g., "vibe finish", "끝까지") as normal text; ask the user to rephrase using `use vf:`.

## Vibe Fast Path

- Use this workflow by default when speed and autonomy are requested.
- Keep phases short; batch small changes to maintain momentum.
- Only raise decisions that risk data loss or major rework.

## Vibe Quick Invoke

- `use vf: <goal>`

## Scope Lock (Required)

- Before any file search, determine scope roots:
  1. If a `.vibe-scope` file exists in the current directory or any parent, use the closest one.
     - Each non-empty, non-comment line is an allowed path.
     - Relative paths are resolved from the `.vibe-scope` file directory.
  2. Else, if inside a git repo, use the repo root.
  3. Else, use the current working directory.
- Only run `rg`, `find`, or any filesystem scans inside the scope roots.
- Never scan `$HOME` or `/` unless the user explicitly asks.

## Overview

Use a strict plan -> execute -> test -> re-plan loop with minimal interruptions.

## Workflow

1. Choose 10 phases by default; use 20 only for large scope or explicit request.
2. Output the phase plan before execution; include goal, actions, and deliverables per phase.
3. Execute all phases end-to-end without asking questions.
4. Make sensible default decisions; record them in Assumptions with brief rationale.
5. Collect only high-risk or irreversible choices in Decision Queue; ask once after all phases finish.
6. Run tests; discover the best command and execute it.
7. If tests fail or issues are found, produce a Retro & Fix Plan with a fresh 10/20-phase plan and stop.

## Decision Policy

1. Prefer safe, reversible defaults.
2. Use least-change options when impact is unclear.
3. Add to Decision Queue only when choices risk data loss, security, large cost, or multi-hour effort.

## Test Discovery

1. Prefer repository-native test scripts and tooling.
2. Detect common stacks and use the standard test command:
   - JavaScript/TypeScript:
     - Choose package manager by lockfile: pnpm/yarn/npm/bun
     - If workspace markers exist, use the workspace test command
     - Otherwise run the root `test` script
   - go.mod: `go test ./...`
   - pyproject.toml or pytest.ini: `pytest`
   - Cargo.toml: `cargo test`
   - Gemfile: `bundle exec rspec` or `bundle exec rake test`
   - pom.xml: `mvn test`
   - build.gradle or gradlew: `./gradlew test`
   - *.sln or *.csproj: `dotnet test`
3. If no tests are found, run the closest available quality check (build or lint) and report the gap.

## Output Format

Use these headings in order:

1. Plan (10 or 20 phases)
2. Execution Log
3. Assumptions
4. Decision Queue (ask now)
5. Tests
6. Retro & Fix Plan (only if needed)

Keep each section concise and actionable.
