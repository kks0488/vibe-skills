$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
$SrcDir = Join-Path $RepoRoot "skills"
$CoreSkillsFile = Join-Path $ScriptDir "core-skills.txt"

function Show-Usage {
@"
Usage: install-skills.ps1 [--user|--repo|--path <dir>] [--agents]

  --core        (legacy) No-op. This repo ships only vc skills.
  --all         (legacy) No-op. This repo ships only vc skills.
  --user        Install to user skills scope (default)
                - default: `$CODEX_HOME\\skills (legacy-compatible)
                - with --agents: ~\\.agents\\skills (Codex docs default)
  --repo        Install to repo skills scope (from current directory)
                - default: <git-root>\\.codex\\skills
                - with --agents: <git-root>\\.agents\\skills
  --path <dir>  Install to an explicit skills directory
  --agents      Use .agents\\skills locations for --user/--repo
"@ | Write-Output
}

function Get-CoreSkills {
  if (-not (Test-Path $CoreSkillsFile)) {
    Write-Error "Error: missing core skills list: $CoreSkillsFile"
    exit 1
  }
  return Get-Content $CoreSkillsFile | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith("#") }
}

$Scope = "user"
$LegacyAll = $false
$CustomDest = $null
$UseAgents = $false
for ($i = 0; $i -lt $Args.Length; $i++) {
  switch ($Args[$i]) {
    "--core" { }
    "--all" { $LegacyAll = $true }
    "--user" { $Scope = "user" }
    "--repo" { $Scope = "repo" }
    "--agents" { $UseAgents = $true }
    "--path" {
      if ($i + 1 -ge $Args.Length) {
        Write-Error "Error: --path requires a directory."
        Show-Usage
        exit 1
      }
      $CustomDest = $Args[$i + 1]
      $i++
    }
    "-h" { Show-Usage; exit 0 }
    "--help" { Show-Usage; exit 0 }
    default {
      Write-Error ("Error: unknown option: " + $Args[$i])
      Show-Usage
      exit 1
    }
  }
}

if ($CustomDest) {
  if ([System.IO.Path]::IsPathRooted($CustomDest)) {
    $DestDir = $CustomDest
  } else {
    $DestDir = Join-Path $PWD.Path $CustomDest
  }
} elseif ($Scope -eq "repo") {
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Error: git is required for --repo."
    exit 1
  }
  $repoRoot = git -C $PWD.Path rev-parse --show-toplevel 2>$null
  if (-not $repoRoot) {
    Write-Error "Error: not inside a git repo. Use --path or run inside a repo."
    exit 1
  }
  if ($UseAgents) {
    $DestDir = Join-Path $repoRoot.Trim() ".agents\\skills"
  } else {
    $DestDir = Join-Path $repoRoot.Trim() ".codex\\skills"
  }
} else {
  if ($UseAgents) {
    $DestDir = Join-Path $HOME ".agents\\skills"
  } else {
    $DestRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
    $DestDir = Join-Path $DestRoot "skills"
  }
}

New-Item -ItemType Directory -Force -Path $DestDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$backupDir = $null
if ($LegacyAll) {
  Write-Output "Note: --all is deprecated; this repo ships only vc skills."
}

$coreSkills = Get-CoreSkills
foreach ($name in $coreSkills) {
  $skillDir = Join-Path $SrcDir $name
  if (-not (Test-Path $skillDir)) {
    Write-Warning "Core skill missing in repo (skipping): $name"
    continue
  }
  $dest = Join-Path $DestDir $name
  if (Test-Path $dest) {
    if (-not $backupDir) {
      $backupDir = Join-Path (Split-Path $DestDir -Parent) ("skills.bak-" + $timestamp)
      New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    }
    Move-Item $dest $backupDir
  }
  Copy-Item $skillDir $dest -Recurse -Force
}

Write-Output "Installed skills to $DestDir"
if ($backupDir) {
  Write-Output "Backup dir: $backupDir"
}
Write-Output "Next: copy/paste into Codex chat:"
$legacySkills = Get-ChildItem $DestDir -Directory -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -like "vibe-*" -or $_.Name -like "vs-*" -or $_.Name -in @("vf", "vg", "vsf", "vsg") } |
  Select-Object -ExpandProperty Name
if ($legacySkills) {
  $legacyList = $legacySkills -join ", "
  Write-Output "Warning: legacy vibe/vs skills detected: $legacyList"
  Write-Output "Tip: remove or rename legacy skills to avoid conflicts."
}
Write-Output '$vcg build a login page'
Write-Output 'Tip: use "$vcf ..." for end-to-end execution with verification.'
Write-Output "Tip: vc mcp docs  (install OpenAI developer docs MCP server)."
