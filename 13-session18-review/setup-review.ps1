# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  setup-review.ps1  -  Session 18, layer 7: the Engineering Excellence Review - a production and operations
#                       readiness checklist, a runbook, a review board's findings and the client's feedback,
#                       decided and the top ones fixed (Windows PowerShell 5.1 / PowerShell 7)
#
#  What it does, once per group:
#    1. Adds the four layer-7 Claude Code commands and the templates
#    2. Starts specs\design\readiness.md - production and operations readiness - with your case's two lines
#    3. Starts ops\runbook.md, specs\review\findings.md and specs\review\feedback.md
#    4. Adds the layer-7 section to CLAUDE.md
#    5. Commits all of it as one commit, on a branch if you are on main
#
#  Never overwrites your files.
#
#  USAGE
#    ./setup-review.ps1 -Path "C:\work\group-1"
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  A bash twin (setup-review.sh) exists for macOS / Linux / WSL.
# =============================================================================
param([Parameter(Mandatory=$true)][string]$Path)

function Ok($m)   { Write-Host "  [ OK ] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red }
function Hdr($m)  { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
$Utf8 = New-Object System.Text.UTF8Encoding $false
function ReadText($p)  { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }
function WriteText($p, $t) { [System.IO.File]::WriteAllText($p, $t, $Utf8) }

$Here = $PSScriptRoot
if (-not (Test-Path $Path)) { Bad "Path not found: $Path"; exit 1 }
$Repo = (Resolve-Path $Path).Path

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Session 18 - set up layer 7"
Write-Host " $Repo"
Write-Host "============================================================"

Hdr "Before we start"
if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository."; exit 1 }
if (git -C $Repo status --porcelain) { Bad "You have uncommitted changes. Commit or stash them first, so this step is one clean commit."; exit 1 }
git -C $Repo rev-parse -q --verify refs/tags/L6-production 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Ok "Tag L6-production found - the review starts from it" }
else { Warn "No tag L6-production - review what you have; what is missing becomes a finding, not a reason to skip the board" }
if (Test-Path (Join-Path $Repo "specs/design/threat-model.md")) { Ok "Threat model found" } else { Warn "No specs/design/threat-model.md - the board will ask (PR-08)" }
if (Test-Path (Join-Path $Repo "specs/design/observability.md")) { Ok "Observability spec found" } else { Warn "No specs/design/observability.md - the board will ask (PR-15)" }
$cur = (git -C $Repo rev-parse --abbrev-ref HEAD).Trim()
$def = (git -C $Repo symbolic-ref --short refs/remotes/origin/HEAD 2>$null)
$def = if ($def) { ($def -replace '^origin/', '').Trim() } else { 'main' }
if ($cur -eq $def) {
  git -C $Repo pull --ff-only --quiet 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok "$def is up to date" } else { Warn "Could not pull $def - carrying on" }
  git -C $Repo rev-parse -q --verify refs/heads/setup/layer-7 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { git -C $Repo switch --quiet setup/layer-7 2>$null; Warn "Branch setup/layer-7 already existed - switched to it" }
  else { git -C $Repo switch --quiet -c setup/layer-7 2>$null; Ok "Created branch setup/layer-7 - main is protected" }
  $cur = 'setup/layer-7'
} else { Ok "Working on branch $cur" }

function Add-File($src, $rel) {   # never overwrites
  $dst = Join-Path $Repo $rel
  $show = $rel -replace '\\', '/'
  if (Test-Path $dst) { Ok "$show already exists - left alone"; return }
  New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
  Copy-Item $src $dst; Ok "$show added"
}

Hdr "1 - Commands and templates"
$cmdDir = Join-Path $Repo ".claude\commands"
New-Item -ItemType Directory -Force -Path $cmdDir | Out-Null
$cmds = @(Get-ChildItem (Join-Path $Here "claude-commands") -Filter *.md)
$cmds | ForEach-Object { Copy-Item $_.FullName $cmdDir -Force }
Ok "$($cmds.Count) layer-7 commands added to .claude/commands/"
foreach ($t in @("readiness.md", "runbook.md", "findings.md", "feedback.md")) { Add-File (Join-Path $Here "templates\$t") "templates\$t" }

Hdr "2 - The readiness checklist"
$rd = Join-Path $Repo "specs\design\readiness.md"
$origin = (git -C $Repo remote get-url origin 2>$null); if (-not $origin) { $origin = $Repo }
$letter = ([regex]::Matches("$origin", 'case-[a-e]') | Select-Object -Last 1).Value
$lines = if ($letter) { Join-Path $Here "templates\case-lines\$letter.md" } else { "" }
if (Test-Path $rd) { Ok "specs/design/readiness.md already exists - left alone" }
else {
  New-Item -ItemType Directory -Force -Path (Split-Path $rd -Parent) | Out-Null
  $tpl = ReadText (Join-Path $Here "templates\readiness.md")
  if ($lines -and (Test-Path $lines)) {
    $snip = (ReadText $lines).TrimEnd("`r", "`n")
    WriteText $rd ([regex]::Replace($tpl, '(?m)^<!-- case lines -->\r?$', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $snip }))
    Ok "specs/design/readiness.md added - 17 production and 12 operations lines, and two lines for $letter"
  } else {
    WriteText $rd $tpl
    Warn "specs/design/readiness.md added - could not tell your case from the repo name: copy your two lines from <lab>/templates/case-lines/case-<letter>.md into section 3"
  }
}

Hdr "3 - Runbook, findings, feedback"
Add-File (Join-Path $Here "templates\runbook.md") "ops\runbook.md"
Add-File (Join-Path $Here "templates\findings.md") "specs\review\findings.md"
Add-File (Join-Path $Here "templates\feedback.md") "specs\review\feedback.md"

Hdr "4 - CLAUDE.md"
$claude = Join-Path $Repo "CLAUDE.md"
if ((Test-Path $claude) -and ((ReadText $claude) -match '(?m)^## Layer 7')) { Ok "CLAUDE.md already has the layer-7 section" }
else {
  $old = if (Test-Path $claude) { ReadText $claude } else { "" }
  WriteText $claude ($old + (ReadText (Join-Path $Here "templates\CLAUDE-layer7.md"))); Ok "Layer-7 section added to CLAUDE.md"
}

Hdr "5 - One commit"
git -C $Repo add -A 2>$null
git -C $Repo diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Ok "Nothing new to commit" }
else {
  git -C $Repo commit -q -m "setup: layer 7 - readiness checklist, runbook, review findings and feedback templates, review commands"
  if ($LASTEXITCODE -eq 0) { Ok "Committed on $cur" } else { Bad "Commit failed - see the message above"; exit 1 }
}

Write-Host ""
Write-Host "Next - step by step in $(Join-Path $Here 'WORKSHOP-S18.md'):"
Write-Host "  2. /readiness-check specs/<slice>  and  /runbook   - every line with evidence, or an honest gap"
Write-Host "  3. /board-brief                    - three minutes: running slice, two numbers, scorecard, your own gaps"
Write-Host "  4. The board - $(Join-Path $Here 'board/rotation.md') and board/rubric.md"
Write-Host "  Check as you go:  ./check-review.ps1 -Path `"$Repo`""
