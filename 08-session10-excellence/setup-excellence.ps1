# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  setup-excellence.ps1  -  Session 10: add the layer 2 templates, commands and
#                            merge request checklist to your case repository
#                            (Windows PowerShell 5.1 / PowerShell 7)
#
#  What it does, once per group:
#    1. Adds templates: engineering rules, plan section 12, review, tech debt
#    2. Adds specs\design\tech-debt.md and the GitLab merge request checklist
#    3. Adds the five Session 10 Claude Code commands and the prompts file
#    4. Adds the Session 10 section to CLAUDE.md
#    5. Commits all of it as one commit
#
#  It never deletes anything, and never overwrites a file you have written.
#
#  USAGE
#    ./setup-excellence.ps1 -Path "C:\work\group-1"
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  A bash twin (setup-excellence.sh) exists for macOS / Linux / WSL.
# =============================================================================
param(
  [Parameter(Mandatory=$true)][string]$Path
)

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
Write-Host " Junior SWAT Labs - Session 10 - set up layer 2"
Write-Host " $Repo"
Write-Host "============================================================"

Hdr "Before we start"
if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository."; exit 1 }
if (-not (Test-Path (Join-Path $Repo "constitution.md"))) { Bad "No constitution.md - finish the Session 9 minimum bar first (07-session09-spec/check-spec)"; exit 1 }
$dirty = git -C $Repo status --porcelain
if ($dirty) {
  Bad "You have uncommitted changes. Commit them first, so this step is one clean commit:"
  Write-Host "      git -C `"$Repo`" add -A ; git -C `"$Repo`" commit -m `"wip: before Session 10`""
  exit 1
}
Ok "Clean git repository with a constitution"

function Add-File($src, $rel) {   # never overwrites
  $dst = Join-Path $Repo $rel
  if (Test-Path $dst) { Ok "$rel already exists - left alone"; return }
  New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
  Copy-Item $src $dst; Ok "$rel added"
}

Hdr "1 - Templates"
foreach ($t in @("engineering-rules","plan-section-12","review","tech-debt")) {
  Add-File (Join-Path $Here "templates\$t.md") "templates\$t.md"
}

Hdr "2 - Debt register and the merge request checklist"
Add-File (Join-Path $Here "templates\tech-debt.md") "specs\design\tech-debt.md"
Add-File (Join-Path $Here "templates\merge_request_template.md") ".gitlab\merge_request_templates\Default.md"

Hdr "3 - Claude Code commands and prompts"
foreach ($d in @(".claude\commands","prompts")) { New-Item -ItemType Directory -Force -Path (Join-Path $Repo $d) | Out-Null }
$n = 0
Get-ChildItem (Join-Path $Here "claude-commands\*.md") | ForEach-Object {
  Copy-Item $_.FullName (Join-Path $Repo ".claude\commands\") -Force; $n++
}
Ok "$n commands added to .claude/commands/"
Copy-Item (Join-Path $Here "prompts\10-excellence.md") (Join-Path $Repo "prompts\") -Force
Ok "prompts/10-excellence.md added"

Hdr "4 - CLAUDE.md"
$claude = Join-Path $Repo "CLAUDE.md"
$block = ReadText (Join-Path $Here "templates\CLAUDE-session10.md")
if (-not (Test-Path $claude)) { WriteText $claude $block; Warn "No CLAUDE.md - created one with just the Session 10 section" }
elseif ((ReadText $claude) -match '(?m)^## Session 10') { Ok "CLAUDE.md already has the Session 10 section" }
else { WriteText $claude ((ReadText $claude) + $block); Ok "Session 10 section added to CLAUDE.md" }

Hdr "5 - One commit"
git -C $Repo add -A
git -C $Repo diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Ok "Nothing new to commit" }
else {
  git -C $Repo commit -q -m "setup: Session 10 - engineering rules, review and refactor commands, MR checklist"
  if ($LASTEXITCODE -eq 0) { Ok "Committed: setup: Session 10 ..." } else { Bad "Commit failed - see the message above"; exit 1 }
}

Write-Host ""
Write-Host "Next:"
Write-Host "  1. git -C `"$Repo`" push"
Write-Host "  2. In Claude Code, from the repository:  /spec-engineering-rules"
Write-Host "  3. Check as you go:  ./check-excellence.ps1 -Path `"$Repo`""
