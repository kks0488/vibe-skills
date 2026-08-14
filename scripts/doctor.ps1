param(
  [switch]$Strict
)

if ($env:VC_DOCTOR_STRICT) {
  $strictValue = $env:VC_DOCTOR_STRICT.Trim().ToLower()
  if ($strictValue -in @("1", "true", "yes")) {
    $Strict = $true
  }
}

$script:TotalSkillIssues = 0

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsRepoRoot = Resolve-Path (Join-Path $ScriptDir "..")

$UserRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$UserSkillsDir = Join-Path $UserRoot "skills"
$UserAgentsSkillsDir = Join-Path $HOME ".agents\skills"

$Cwd = $PWD.Path
$CwdSkillsDir = Join-Path $Cwd ".codex\skills"
$CwdAgentsSkillsDir = Join-Path $Cwd ".agents\skills"
$RepoRoot = $null
$RepoSkillsDir = $null
$RepoAgentsSkillsDir = $null
$SourceSkillsDir = Join-Path $SkillsRepoRoot "skills"

if (Get-Command git -ErrorAction SilentlyContinue) {
  $inRepo = git -C $Cwd rev-parse --is-inside-work-tree 2>$null
  if ($LASTEXITCODE -eq 0) {
    $RepoRoot = (git -C $Cwd rev-parse --show-toplevel 2>$null).Trim()
    if ($RepoRoot) {
      $RepoSkillsDir = Join-Path $RepoRoot ".codex\skills"
      $RepoAgentsSkillsDir = Join-Path $RepoRoot ".agents\skills"
    }
  }
}

Write-Output "VC Skills Doctor"
Write-Output "CODEX_HOME: $UserRoot"
if (Get-Command codex -ErrorAction SilentlyContinue) {
  try {
    $codexCmd = Get-Command codex
    $codexVersion = (& codex --version 2>$null)
    if ($codexVersion) {
      Write-Output ("codex: " + $codexVersion.Trim() + " (" + $codexCmd.Source + ")")
    }
  } catch {
    # ignore
  }
}

$configFile = Join-Path $UserRoot "config.toml"
if (Test-Path $configFile) {
  $configText = Get-Content $configFile -Raw
  $hasServer = $configText -match "(?m)^\\[mcp_servers\\.openaiDeveloperDocs\\]\\s*$"
  $hasUrl = $configText -match "developers\\.openai\\.com/mcp"
  if ($hasServer -and $hasUrl) {
    Write-Output "OpenAI Docs MCP: configured (openaiDeveloperDocs)"
  } else {
    Write-Output "OpenAI Docs MCP: not configured (openaiDeveloperDocs)"
    Write-Output "Tip: vc mcp docs  (or: codex mcp add openaiDeveloperDocs --url https://developers.openai.com/mcp)"
  }
} else {
  Write-Output "Config not found: $configFile"
  Write-Output "Tip: vc mcp docs  (or: codex mcp add openaiDeveloperDocs --url https://developers.openai.com/mcp)"
}

function Get-SkillCount([string]$dir) {
  return (Get-ChildItem $dir -Directory -ErrorAction SilentlyContinue |
    Where-Object { -not $_.Name.StartsWith(".") -and (Test-Path (Join-Path $_.FullName "SKILL.md")) } |
    Measure-Object).Count
}

function Test-Skill([string]$skillDir) {
  $skillFile = Join-Path $skillDir "SKILL.md"
  $skillJson = Join-Path $skillDir "SKILL.json"
  $skillOpenaiYaml = Join-Path (Join-Path $skillDir "agents") "openai.yaml"
  if (-not (Test-Path $skillFile)) {
    Write-Output "WARN: missing SKILL.md: $skillDir"
    return $false
  }

  $lines = Get-Content $skillFile
  if (-not $lines -or $lines.Count -eq 0) {
    Write-Output "WARN: empty SKILL.md: $skillFile"
    return $false
  }

  if ($lines[0].Trim() -ne "---") {
    Write-Output "WARN: missing frontmatter: $skillFile"
    return $false
  }

  $endIndex = $null
  for ($i = 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq "---") {
      $endIndex = $i
      break
    }
  }
  if ($endIndex -eq $null) {
    Write-Output "WARN: unterminated frontmatter: $skillFile"
    return $false
  }

  $frontmatter = @()
  if ($endIndex -gt 1) {
    $frontmatter = $lines[1..($endIndex - 1)]
  }

  $nameLine = $frontmatter | Where-Object { $_ -match '^\s*name\s*:' } | Select-Object -First 1
  $descLine = $frontmatter | Where-Object { $_ -match '^\s*description\s*:' } | Select-Object -First 1
  $shortDescLine = $frontmatter | Where-Object { $_ -match '^\s*short-description\s*:' } | Select-Object -First 1

  $name = if ($nameLine) { ($nameLine -replace '^\s*name\s*:\s*', '').Trim() } else { "" }
  $desc = if ($descLine) { ($descLine -replace '^\s*description\s*:\s*', '').Trim() } else { "" }
  $shortDesc = if ($shortDescLine) { ($shortDescLine -replace '^\s*short-description\s*:\s*', '').Trim() } else { "" }

  if (-not $name) {
    Write-Output "WARN: missing name: $skillFile"
    return $false
  }
  if (-not $desc) {
    Write-Output "WARN: missing description: $skillFile"
    return $false
  }

  $dirName = Split-Path $skillDir -Leaf
  $nameClean = $name.Trim()
  $nameClean = $nameClean.Trim('"')
  $nameClean = $nameClean.Trim("'")
  if ($dirName -ne $nameClean) {
    Write-Output "WARN: skill dir name mismatch (dir=$dirName, frontmatter name=$nameClean): $skillFile"
    return $false
  }

  # Match Codex CLI constraints (codex-rs/core/src/skills/loader.rs).
  if ($name.Length -gt 64) {
    Write-Output "WARN: name too long ($($name.Length) > 64): $skillFile"
    return $false
  }
  if ($desc.Length -gt 1024) {
    Write-Output "WARN: description too long ($($desc.Length) > 1024): $skillFile"
    return $false
  }
  if ($shortDesc -and $shortDesc.Length -gt 1024) {
    Write-Output "WARN: metadata.short-description too long ($($shortDesc.Length) > 1024): $skillFile"
    return $false
  }

  function Normalize-SingleLine([string]$value) {
    if (-not $value) { return "" }
    return (($value -split "\\s+") -join " ").Trim()
  }

  function Test-OptionalField([string]$field, [object]$value, [int]$maxLen, [string]$path) {
    if ($null -eq $value) { return $true }
    if (-not ($value -is [string])) {
      Write-Output "WARN: invalid $field (expected string): $path"
      return $false
    }
    $v = Normalize-SingleLine $value
    if (-not $v) {
      Write-Output "WARN: invalid $field (empty): $path"
      return $false
    }
    if ($v.Length -gt $maxLen) {
      Write-Output "WARN: invalid $field (exceeds $maxLen chars): $path"
      return $false
    }
    return $true
  }

  function Test-RequiredField([string]$field, [object]$value, [int]$maxLen, [string]$path) {
    if ($null -eq $value) {
      Write-Output "WARN: invalid $field (missing): $path"
      return $false
    }
    return (Test-OptionalField $field $value $maxLen $path)
  }

  function Read-MetadataJson([string]$path) {
    if (-not (Test-Path $path)) {
      return $null
    }
    try {
      return (Get-Content $path -Raw | ConvertFrom-Json -ErrorAction Stop)
    } catch {
      Write-Output "WARN: invalid metadata JSON ($($_.Exception.Message)): $path"
      return $null
    }
  }

  function Test-LooksLikeJson([string]$path) {
    if (-not (Test-Path $path)) { return $false }
    try {
      foreach ($line in (Get-Content $path -ErrorAction Stop)) {
        $t = $line.Trim()
        if (-not $t) { continue }
        if ($t.StartsWith("#")) { continue }
        $c = $t.Substring(0, 1)
        return ($c -eq "{" -or $c -eq "[")
      }
    } catch {
      return $false
    }
    return $false
  }

  function Test-MetadataObject([object]$json, [string]$path) {
    if (-not $json) { return $true }

    if ($json.interface) {
      if (-not (Test-OptionalField "interface.display_name" $json.interface.display_name 64 $path)) { return $false }
      if (-not (Test-OptionalField "interface.short_description" $json.interface.short_description 1024 $path)) { return $false }
      if (-not (Test-OptionalField "interface.default_prompt" $json.interface.default_prompt 1024 $path)) { return $false }

      $brand = $json.interface.brand_color
      if ($null -ne $brand) {
        if (-not ($brand -is [string]) -or -not ($brand.Trim() -match '^#[0-9A-Fa-f]{6}$')) {
          Write-Output "WARN: invalid interface.brand_color (expected #RRGGBB): $path"
          return $false
        }
      }
    }

    if ($json.dependencies -and $json.dependencies.tools) {
      if (-not ($json.dependencies.tools -is [System.Collections.IEnumerable])) {
        Write-Output "WARN: invalid dependencies.tools (expected array): $path"
        return $false
      }
      $i = 0
      foreach ($tool in $json.dependencies.tools) {
        if (-not $tool) {
          Write-Output "WARN: invalid dependencies.tools[$i] (empty): $path"
          return $false
        }
        if (-not (Test-RequiredField "dependencies.tools[$i].type" $tool.type 64 $path)) { return $false }
        if (-not (Test-RequiredField "dependencies.tools[$i].value" $tool.value 1024 $path)) { return $false }
        if (-not (Test-OptionalField "dependencies.tools[$i].description" $tool.description 1024 $path)) { return $false }
        if (-not (Test-OptionalField "dependencies.tools[$i].transport" $tool.transport 64 $path)) { return $false }
        if (-not (Test-OptionalField "dependencies.tools[$i].command" $tool.command 1024 $path)) { return $false }
        if (-not (Test-OptionalField "dependencies.tools[$i].url" $tool.url 1024 $path)) { return $false }

        # Basic MCP dependency sanity (matches codex-rs/core/src/mcp/skill_dependencies.rs expectations).
        $toolType = (Normalize-SingleLine ([string]$tool.type)).ToLower()
        if ($toolType -eq "mcp") {
          $transport = if ($tool.transport) { (Normalize-SingleLine ([string]$tool.transport)).ToLower() } else { "streamable_http" }
          if ($transport -eq "streamable_http") {
            if (-not $tool.url -or -not (Normalize-SingleLine ([string]$tool.url))) {
              Write-Output "WARN: invalid dependencies.tools[$i] (mcp streamable_http requires url): $path"
              return $false
            }
          } elseif ($transport -eq "stdio") {
            if (-not $tool.command -or -not (Normalize-SingleLine ([string]$tool.command))) {
              Write-Output "WARN: invalid dependencies.tools[$i] (mcp stdio requires command): $path"
              return $false
            }
          } else {
            Write-Output "WARN: invalid dependencies.tools[$i] (mcp unsupported transport): $path"
            return $false
          }
        }
        $i++
      }
    }

    return $true
  }

  function Normalize-Metadata([object]$json) {
    $interfaceNorm = [ordered]@{}
    if ($json -and $json.interface) {
      foreach ($k in @("display_name", "short_description", "brand_color", "default_prompt")) {
        $v = $json.interface.$k
        if ($null -ne $v) { $interfaceNorm[$k] = $v }
      }
    }

    $toolsNorm = @()
    if ($json -and $json.dependencies -and $json.dependencies.tools) {
      foreach ($tool in $json.dependencies.tools) {
        if (-not $tool) { continue }
        $entry = [ordered]@{}
        foreach ($k in @("type", "value", "description", "transport", "command", "url")) {
          $v = $tool.$k
          if ($null -ne $v) { $entry[$k] = $v }
        }
        if ($entry.Count -gt 0) { $toolsNorm += $entry }
      }
    }
    $toolsNorm = $toolsNorm | Sort-Object `
      @{Expression = { $_.type }}, `
      @{Expression = { $_.value }}, `
      @{Expression = { $_.transport }}, `
      @{Expression = { $_.url }}, `
      @{Expression = { $_.command }}, `
      @{Expression = { $_.description }}

    return [ordered]@{
      interface = $interfaceNorm
      dependencies = [ordered]@{ tools = @($toolsNorm) }
    }
  }

  $openaiYamlObj = $null
  if (Test-Path $skillOpenaiYaml) {
    # Codex skill metadata is YAML at `agents/openai.yaml`, but JSON is a YAML subset.
    # Validate JSON-formatted files; non-JSON YAML is skipped (Codex itself is fail-open on metadata).
    if (Test-LooksLikeJson $skillOpenaiYaml) {
      $openaiYamlObj = Read-MetadataJson $skillOpenaiYaml
      if ($null -eq $openaiYamlObj) { return $false }
      if (-not (Test-MetadataObject $openaiYamlObj $skillOpenaiYaml)) { return $false }
    }
  }

  $skillJsonObj = $null
  if (Test-Path $skillJson) {
    $skillJsonObj = Read-MetadataJson $skillJson
    if ($null -eq $skillJsonObj) { return $false }
    if (-not (Test-MetadataObject $skillJsonObj $skillJson)) { return $false }
  }

  if ($openaiYamlObj -and $skillJsonObj) {
    $a = Normalize-Metadata $openaiYamlObj | ConvertTo-Json -Compress -Depth 10
    $b = Normalize-Metadata $skillJsonObj | ConvertTo-Json -Compress -Depth 10
    if ($a -ne $b) {
      Write-Output "WARN: metadata mismatch between agents\\openai.yaml and SKILL.json: $skillOpenaiYaml vs $skillJson"
      return $false
    }
  }

  return $true
}

function Test-SkillsDir([string]$dir, [string]$label) {
  if (-not (Test-Path $dir)) {
    return
  }

  Write-Output "Checking skill metadata ($label): $dir"
  $issues = 0
  $skipped = 0
  Get-ChildItem $dir -Directory -ErrorAction SilentlyContinue |
    Where-Object { -not $_.Name.StartsWith(".") } |
    ForEach-Object {
      if (-not (Test-Path (Join-Path $_.FullName "SKILL.md"))) {
        $skipped++
        return
      }
      if (-not (Test-Skill $_.FullName)) {
        $issues++
      }
    }

  if ($issues -eq 0) {
    Write-Output "Skill metadata OK ($label)"
  } else {
    Write-Output "Skill metadata issues: $issues ($label)"
  }
  if ($skipped -ne 0) {
    Write-Output "Skipped non-skill dirs (no SKILL.md): $skipped ($label)"
  }

  $script:TotalSkillIssues += $issues
}

if (Test-Path $UserAgentsSkillsDir) {
  $count = Get-SkillCount $UserAgentsSkillsDir
  Write-Output "Skills dir (user, .agents): $UserAgentsSkillsDir ($count installed)"
  $legacyBackups = Get-ChildItem $UserAgentsSkillsDir -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "*.bak-*" } |
    Select-Object -ExpandProperty Name
  if ($legacyBackups) {
    $legacyList = $legacyBackups -join ", "
    Write-Output "WARN: legacy backup skill folders detected (will load as duplicate skills): $legacyList"
    Write-Output "Tip: move them out of $UserAgentsSkillsDir (e.g. $HOME\.agents\skills.bak-<timestamp>) or delete them."
  }
} else {
  Write-Output "Skills dir not found: $UserAgentsSkillsDir"
}

if (Test-Path $UserSkillsDir) {
  $count = Get-SkillCount $UserSkillsDir
  Write-Output "Skills dir (user, legacy): $UserSkillsDir ($count installed)"
  $legacyBackups = Get-ChildItem $UserSkillsDir -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "*.bak-*" } |
    Select-Object -ExpandProperty Name
  if ($legacyBackups) {
    $legacyList = $legacyBackups -join ", "
    Write-Output "WARN: legacy backup skill folders detected (will load as duplicate skills): $legacyList"
    Write-Output "Tip: move them out of $UserSkillsDir (e.g. $UserRoot\\skills.bak-<timestamp>) or delete them."
  }
} else {
  Write-Output "Skills dir not found: $UserSkillsDir"
}

if (Test-Path $CwdSkillsDir) {
  $count = Get-SkillCount $CwdSkillsDir
  Write-Output "Skills dir (repo cwd): $CwdSkillsDir ($count installed)"
}
if (Test-Path $CwdAgentsSkillsDir) {
  $count = Get-SkillCount $CwdAgentsSkillsDir
  Write-Output "Skills dir (repo cwd, .agents): $CwdAgentsSkillsDir ($count installed)"
}

if ($RepoSkillsDir -and ($RepoSkillsDir -ne $CwdSkillsDir) -and (Test-Path $RepoSkillsDir)) {
  $count = Get-SkillCount $RepoSkillsDir
  Write-Output "Skills dir (repo root): $RepoSkillsDir ($count installed)"
}
if ($RepoAgentsSkillsDir -and ($RepoAgentsSkillsDir -ne $CwdAgentsSkillsDir) -and (Test-Path $RepoAgentsSkillsDir)) {
  $count = Get-SkillCount $RepoAgentsSkillsDir
  Write-Output "Skills dir (repo root, .agents): $RepoAgentsSkillsDir ($count installed)"
}

if (Test-Path (Join-Path $SkillsRepoRoot ".git")) {
  Write-Output "Repo: $SkillsRepoRoot"
  $branch = git -C $SkillsRepoRoot rev-parse --abbrev-ref HEAD
  $commit = git -C $SkillsRepoRoot rev-parse --short HEAD
  Write-Output "Branch: $branch"
  Write-Output "Commit: $commit"
  $versionFile = Join-Path $SkillsRepoRoot "VERSION"
  if (Test-Path $versionFile) {
    $version = (Get-Content $versionFile -Raw).Trim()
    if ($version) {
      Write-Output "Version: $version"
    }
  }
} else {
  $RepoDir = if ($env:VC_SKILLS_HOME) { $env:VC_SKILLS_HOME } elseif ($env:VS_SKILLS_HOME) { $env:VS_SKILLS_HOME } elseif ($env:VIBE_SKILLS_HOME) { $env:VIBE_SKILLS_HOME } else { Join-Path $HOME ".vc-skills" }
  Write-Output "Repo not found at: $RepoDir"
  Write-Output "Tip: set VC_SKILLS_HOME (or legacy VS_SKILLS_HOME/VIBE_SKILLS_HOME) or run the bootstrap one-liner."
}

$coreSkill = $null
if (Test-Path (Join-Path $UserAgentsSkillsDir "vc-router")) {
  $coreSkill = $UserAgentsSkillsDir
} elseif (Test-Path (Join-Path $UserSkillsDir "vc-router")) {
  $coreSkill = $UserSkillsDir
} elseif (Test-Path (Join-Path $CwdSkillsDir "vc-router")) {
  $coreSkill = $CwdSkillsDir
} elseif (Test-Path (Join-Path $CwdAgentsSkillsDir "vc-router")) {
  $coreSkill = $CwdAgentsSkillsDir
} elseif ($RepoSkillsDir -and (Test-Path (Join-Path $RepoSkillsDir "vc-router"))) {
  $coreSkill = $RepoSkillsDir
} elseif ($RepoAgentsSkillsDir -and (Test-Path (Join-Path $RepoAgentsSkillsDir "vc-router"))) {
  $coreSkill = $RepoAgentsSkillsDir
} elseif (Test-Path (Join-Path $SourceSkillsDir "vc-router")) {
  $coreSkill = $SourceSkillsDir
}

if ($coreSkill) {
  Write-Output "Core skill present: vc-router ($coreSkill)"
} else {
  Write-Output "Core skill missing: vc-router"
}

Test-SkillsDir $UserAgentsSkillsDir "user-agents"
Test-SkillsDir $UserSkillsDir "user-legacy"
Test-SkillsDir $CwdSkillsDir "repo-cwd"
Test-SkillsDir $CwdAgentsSkillsDir "repo-cwd-agents"
Test-SkillsDir $SourceSkillsDir "source"
if ($RepoSkillsDir -and ($RepoSkillsDir -ne $CwdSkillsDir)) {
  Test-SkillsDir $RepoSkillsDir "repo-root"
}
if ($RepoAgentsSkillsDir -and ($RepoAgentsSkillsDir -ne $CwdAgentsSkillsDir)) {
  Test-SkillsDir $RepoAgentsSkillsDir "repo-root-agents"
}

Write-Output "Next: copy/paste into Codex chat:"
$legacySkills = @()
foreach ($scanDir in @($UserSkillsDir, $UserAgentsSkillsDir)) {
  if (-not (Test-Path $scanDir)) {
    continue
  }
  $legacySkills += Get-ChildItem $scanDir -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "vibe-*" -or $_.Name -like "vs-*" -or $_.Name -in @("vf", "vg", "vsf", "vsg") } |
    Select-Object -ExpandProperty Name
}
$legacySkills = $legacySkills | Sort-Object -Unique
if ($legacySkills) {
  $legacyList = $legacySkills -join ", "
  Write-Output "Warning: legacy vibe/vs skills detected: $legacyList"
  Write-Output "Tip: remove or rename legacy skills to avoid conflicts."
}
Write-Output '$vcg build a login page'
Write-Output 'Tip: use "$vcf ..." for end-to-end execution with verification.'

if ($Strict -and $script:TotalSkillIssues -gt 0) {
  Write-Error ("ERROR: skill metadata issues detected: " + $script:TotalSkillIssues)
  exit 1
}
