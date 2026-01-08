param(
  [string]$Command = "help",
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")

switch ($Command.ToLower()) {
  "install" { & (Join-Path $RepoRoot "scripts/install-skills.ps1") }
  "update" { & (Join-Path $RepoRoot "scripts/update-skills.ps1") }
  "doctor" { & (Join-Path $RepoRoot "scripts/doctor.ps1") }
  "list" { & (Join-Path $RepoRoot "scripts/list-skills.ps1") }
  "uninstall" { & (Join-Path $RepoRoot "scripts/uninstall-skills.ps1") }
  "prompts" {
    $promptArg = if ($Args -and $Args.Length -gt 0) { $Args[0] } else { "all" }
    & (Join-Path $RepoRoot "scripts/role-prompts.ps1") $promptArg
  }
  "go" {
    if (-not $Args -or $Args.Length -eq 0) {
      Write-Error "Usage: vibe go <goal>"
      exit 1
    }
    $goal = $Args -join " "
    Write-Output ("끝까지: " + $goal)
  }
  default {
    @"
vibe commands:
  install    install skills into ~/.codex/skills
  update     pull repo + reinstall skills
  doctor     check install status
  list       list installed skills
  uninstall  remove skills (backup)
  prompts    print author/reviewer prompts
  go         print a short finish-to-end prompt
"@ | Write-Output
  }
}
