$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")

Set-Location $RepoRoot
git pull --ff-only
& (Join-Path $RepoRoot "scripts/install-skills.ps1")
