param(
  [string]$Command = "help",
  [string]$Arg = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")

switch ($Command.ToLower()) {
  "install" { & (Join-Path $RepoRoot "scripts/install-skills.ps1") }
  "update" { & (Join-Path $RepoRoot "scripts/update-skills.ps1") }
  "doctor" { & (Join-Path $RepoRoot "scripts/doctor.ps1") }
  "list" { & (Join-Path $RepoRoot "scripts/list-skills.ps1") }
  "uninstall" { & (Join-Path $RepoRoot "scripts/uninstall-skills.ps1") }
  "prompts" { & (Join-Path $RepoRoot "scripts/role-prompts.ps1") $Arg }
  "go" {
    if (-not $Arg) {
      Write-Error "Usage: vibe go \"<goal>\""
      exit 1
    }
    Write-Output ("끝까지: " + $Arg)
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
