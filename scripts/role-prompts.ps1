$which = if ($args.Count -ge 1) { $args[0].ToLower() } else { "all" }

switch ($which) {
  "author" { $mode = "author" }
  "a" { $mode = "author" }
  "reviewer" { $mode = "reviewer" }
  "review" { $mode = "reviewer" }
  "r" { $mode = "reviewer" }
  "all" { $mode = "all" }
  default {
    Write-Error "Usage: role-prompts.ps1 [author|reviewer|all]"
    exit 1
  }
}

if ($mode -eq "author" -or $mode -eq "all") {
  @"
Role: Terminal A (Author).
Rules: Only edit/commit/push. Assume defaults and record assumptions. Ask questions only at the end. Communicate via PR.
"@ | Write-Output
}

if ($mode -eq "all") { "" | Write-Output }

if ($mode -eq "reviewer" -or $mode -eq "all") {
  @"
Role: Terminal B (Reviewer).
Rules: Do not edit code. Review diffs, run tests, and leave PR comments. Request changes from A.
"@ | Write-Output
}
