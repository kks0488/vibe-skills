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

$RepoDir = if ($env:VIBE_SKILLS_HOME) { $env:VIBE_SKILLS_HOME } else { Join-Path $HOME ".vibe-skills" }
if (Test-Path (Join-Path $RepoDir ".git")) {
  Write-Output "Repo: $RepoDir"
  $branch = git -C $RepoDir rev-parse --abbrev-ref HEAD
  $commit = git -C $RepoDir rev-parse --short HEAD
  Write-Output "Branch: $branch"
  Write-Output "Commit: $commit"
} else {
  Write-Output "Repo not found at: $RepoDir"
  Write-Output "Tip: set VIBE_SKILLS_HOME or run the bootstrap one-liner."
}

if (Test-Path (Join-Path $SkillsDir "vibe-router")) {
  Write-Output "Core skill present: vibe-router"
} else {
  Write-Output "Core skill missing: vibe-router"
}

Write-Output "Next: use vibe-router: <goal>"
