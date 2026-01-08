$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
$SrcDir = Join-Path $RepoRoot "skills"

$DestRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$DestDir = Join-Path $DestRoot "skills"

if (-not (Test-Path $DestDir)) {
  Write-Error "Skills dir not found: $DestDir"
  exit 1
}

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$BackupDir = Join-Path $DestRoot ("skills.bak-" + $timestamp)
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

$removed = 0
Get-ChildItem $SrcDir -Directory | ForEach-Object {
  $dest = Join-Path $DestDir $_.Name
  if (Test-Path $dest) {
    Move-Item $dest $BackupDir
    $removed++
  }
}

Write-Output "Removed $removed skill(s)."
Write-Output "Backup dir: $BackupDir"
