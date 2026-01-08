$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
$SrcDir = Join-Path $RepoRoot "skills"

$DestRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$DestDir = Join-Path $DestRoot "skills"

New-Item -ItemType Directory -Force -Path $DestDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
Get-ChildItem $SrcDir -Directory | ForEach-Object {
  $dest = Join-Path $DestDir $_.Name
  if (Test-Path $dest) {
    Rename-Item $dest ($dest + ".bak-" + $timestamp)
  }
  Copy-Item $_.FullName $dest -Recurse -Force
}

Write-Output "Installed skills to $DestDir"
Write-Output "Backup suffix (if any): .bak-$timestamp"
Write-Output "Next: 끝까지: <goal>  (or vibe go <goal>)"
