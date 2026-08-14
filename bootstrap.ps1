$RepoUrl = "https://github.com/kks0488/vibe-codex.git"
$Dest = if ($env:VC_SKILLS_HOME) { $env:VC_SKILLS_HOME } elseif ($env:VS_SKILLS_HOME) { $env:VS_SKILLS_HOME } elseif ($env:VIBE_SKILLS_HOME) { $env:VIBE_SKILLS_HOME } else { Join-Path $HOME ".vc-skills" }

if (Get-Command git -ErrorAction SilentlyContinue) {
  if (Test-Path (Join-Path $Dest ".git")) {
    git -C $Dest pull --ff-only
  } else {
    git clone $RepoUrl $Dest
  }
} else {
  Write-Error "git is required. Install git first and re-run."
  exit 1
}

& (Join-Path $Dest "scripts/install-skills.ps1") --agents

$BinDir = Join-Path $Dest "bin"
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
$Wrapper = Join-Path $BinDir "vc.ps1"
@"
param(
  [string]`$Command = "help",
  [string]`$Arg = ""
)
& `"$Dest\\scripts\\vc.ps1`" `$Command `$Arg
"@ | Set-Content -Path $Wrapper -Encoding UTF8

Write-Output "Command installed: $Wrapper"
Write-Output "Tip: run `"$Wrapper install`" if 'vc' is not in PATH."
