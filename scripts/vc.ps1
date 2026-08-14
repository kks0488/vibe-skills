param(
  [string]$Command = "help",
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")

switch ($Command.ToLower()) {
  "install" { & (Join-Path $RepoRoot "scripts/install-skills.ps1") @Args }
  "update" { & (Join-Path $RepoRoot "scripts/update-skills.ps1") @Args }
  "doctor" { & (Join-Path $RepoRoot "scripts/doctor.ps1") @Args }
  "list" { & (Join-Path $RepoRoot "scripts/list-skills.ps1") @Args }
  "scope" { & (Join-Path $RepoRoot "scripts/scope-init.ps1") @Args }
  "uninstall" { & (Join-Path $RepoRoot "scripts/uninstall-skills.ps1") @Args }
  "prune" { & (Join-Path $RepoRoot "scripts/prune-skills.ps1") @Args }
  "prompts" {
    $promptArg = if ($Args -and $Args.Length -gt 0) { $Args[0] } else { "all" }
    & (Join-Path $RepoRoot "scripts/role-prompts.ps1") $promptArg
  }
  "mcp" {
    $sub = if ($Args -and $Args.Length -gt 0) { $Args[0].ToLower() } else { "help" }

    switch ($sub) {
      { $_ -in @("docs", "devdocs") } {
        if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
          Write-Error "Error: codex not found in PATH."
          Write-Error "Install Codex CLI, then re-run."
          Write-Error "Docs MCP: codex mcp add openaiDeveloperDocs --url https://developers.openai.com/mcp"
          exit 1
        }
        & codex mcp add openaiDeveloperDocs --url "https://developers.openai.com/mcp"
      }
      { $_ -in @("skills", "vibes", "vibe") } {
        if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
          Write-Error "Error: codex not found in PATH."
          Write-Error "Install Codex CLI, then re-run."
          Write-Error "vibe skills MCP: codex mcp add vibeSkills -- npx -y @kyoungsookim/skills-mcp-server"
          exit 1
        }
        & codex mcp add vibeSkills -- npx -y "@kyoungsookim/skills-mcp-server"
      }
      "list" {
        if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
          Write-Error "Error: codex not found in PATH."
          Write-Error "Install Codex CLI, then re-run."
          exit 1
        }
        & codex mcp list
      }
      default {
@"
vc mcp commands:
  vc mcp docs     add OpenAI developer docs MCP server
  vc mcp skills   add vibe skills MCP server (npx)
  vc mcp list     list configured MCP servers
"@ | Write-Output
      }
    }
  }
  { $_ -in @("go", "finish") } {
    if (-not $Args -or $Args.Length -eq 0) {
      Write-Error ("Usage: vc " + $Command.ToLower() + " <goal>")
      Write-Error ("Example: vc " + $Command.ToLower() + " build a login page")
      Write-Error "Tip: include a goal so Codex doesn't have to ask for one."
      exit 1
    }
    $goal = $Args -join " "
    Write-Error "Copy/paste into Codex chat:"
    $prefix = if ($Command.ToLower() -eq "go") { '$vcg ' } else { '$vcf ' }
    Write-Output ($prefix + $goal)
  }
  "teams" {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
      Write-Error "Error: node not found in PATH."
      Write-Error "Install Node.js, then re-run."
      exit 1
    }
    & node (Join-Path $RepoRoot "scripts/vc-teams.js") @Args
  }
  "sync" {
    if (-not $Args -or $Args.Length -eq 0) {
      Write-Error "Usage: vc sync <host> [host...]"
      exit 1
    }
    & (Join-Path $RepoRoot "scripts/update-skills.ps1")
    foreach ($host in $Args) {
      Write-Output "Updating $host"
      ssh $host "curl -fsSL https://raw.githubusercontent.com/kks0488/vibe-codex/main/bootstrap.sh | bash"
    }
  }
  default {
    @"
vc commands:
  install    install vc skills (supports --repo/--path/--agents)
  update     pull repo + reinstall skills (supports --repo/--path/--agents)
  doctor     check install status
  list       list installed skills (supports --repo/--path/--agents)
  teams      manage Agent Teams (create/send/status/prune)
  mcp        manage Codex MCP servers (docs/skills)
  scope      manage .vc-scope (create/add/show)
  uninstall  remove skills (backup; supports --repo/--path/--agents)
  prune      remove legacy removed skills (backup; supports --repo/--path/--agents)
  prompts    print author/reviewer prompts
  go         router mode (prints "`$vcg ...")
  finish     end-to-end mode (prints "`$vcf ...")
  sync       update local + remote host(s)
"@ | Write-Output
  }
}
