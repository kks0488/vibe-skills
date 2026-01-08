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
Write-Output "Next: 끝까지: 원하는 목표를 적어줘 (예: 끝까지: 로그인페이지 만들어줘)"
Write-Output "      or vibe go 로그인페이지 만들어줘 / vibe finish 로그인페이지 만들어줘"
