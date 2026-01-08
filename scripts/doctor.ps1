$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")

$DestRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$SkillsDir = Join-Path $DestRoot "skills"

Write-Output "Vibe Skills Doctor"
Write-Output "CODEX_HOME: $DestRoot"

if (Test-Path $SkillsDir) {
  $count = (Get-ChildItem $SkillsDir -Directory | Measure-Object).Count
  Write-Output "Skills dir: $SkillsDir ($count installed)"
} else {
  Write-Output "Skills dir not found: $SkillsDir"
}

if (Test-Path (Join-Path $RepoRoot ".git")) {
  Write-Output "Repo: $RepoRoot"
  $branch = git -C $RepoRoot rev-parse --abbrev-ref HEAD
  $commit = git -C $RepoRoot rev-parse --short HEAD
  Write-Output "Branch: $branch"
  Write-Output "Commit: $commit"
} else {
  $RepoDir = if ($env:VIBE_SKILLS_HOME) { $env:VIBE_SKILLS_HOME } else { Join-Path $HOME ".vibe-skills" }
  Write-Output "Repo not found at: $RepoDir"
  Write-Output "Tip: set VIBE_SKILLS_HOME or run the bootstrap one-liner."
}

if (Test-Path (Join-Path $SkillsDir "vibe-router")) {
  Write-Output "Core skill present: vibe-router"
} else {
  Write-Output "Core skill missing: vibe-router"
}

Write-Output "Next: 끝까지: <goal>  (or vibe go \"<goal>\")"
