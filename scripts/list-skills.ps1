$DestRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$SkillsDir = Join-Path $DestRoot "skills"

if (-not (Test-Path $SkillsDir)) {
  Write-Error "Skills dir not found: $SkillsDir"
  exit 1
}

Get-ChildItem $SkillsDir -Directory | Select-Object -ExpandProperty Name | Sort-Object
