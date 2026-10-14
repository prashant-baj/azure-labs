# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  setup-ai-engineering.ps1  -  Sessions 11 and 12, layer 3: add the AI review
#                                pipeline job, commands and templates
#                                (Windows PowerShell 5.1 / PowerShell 7)
#
#  What it does, once per group:
#    1. Adds ci\ai-review.yml, ci\review-mr.md, ci\post-review.mjs
#    2. Creates .gitlab-ci.yml with the AI review included - or adds the include
#    3. Adds the ten layer-3 Claude Code commands, templates, prompts and the Azure lab constraints
#    4. Adds the layer-3 section to CLAUDE.md
#    5. Commits all of it as one commit
#
#  It never deletes anything, and never overwrites a file you have written.
#
#  USAGE
#    ./setup-ai-engineering.ps1 -Path "C:\work\group-1"
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  A bash twin (setup-ai-engineering.sh) exists for macOS / Linux / WSL.
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
Write-Host " Junior SWAT Labs - Sessions 11-12 - set up layer 3"
Write-Host " $Repo"
Write-Host "============================================================"

Hdr "Before we start"
if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository."; exit 1 }
if (-not (Test-Path (Join-Path $Repo "constitution.md"))) { Bad "No constitution.md - layers 1 and 2 come first"; exit 1 }
$dirty = git -C $Repo status --porcelain
if ($dirty) {
  Bad "You have uncommitted changes. Commit them first, so this step is one clean commit:"
  Write-Host "      git -C `"$Repo`" add -A ; git -C `"$Repo`" commit -m `"wip: before Session 11`""
  exit 1
}
git -C $Repo rev-parse -q --verify refs/tags/L2-design 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Ok "Tag L2-design found - layer 3 starts from it" }
else { Warn "No tag L2-design - layer 2 is not tagged yet. Carry on, and tag what you have" }

function Add-File($src, $rel) {   # never overwrites
  $dst = Join-Path $Repo $rel
  if (Test-Path $dst) { Ok "$rel already exists - left alone"; return }
  New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
  Copy-Item $src $dst; Ok "$rel added"
}

Hdr "1 - The AI review job"
foreach ($f in @("ai-review.yml","review-mr.md","post-review.mjs")) { Add-File (Join-Path $Here "ci\$f") "ci\$f" }

Hdr "2 - .gitlab-ci.yml"
$ci = Join-Path $Repo ".gitlab-ci.yml"
if (-not (Test-Path $ci)) { Copy-Item (Join-Path $Here "templates\gitlab-ci-starter.yml") $ci; Ok ".gitlab-ci.yml created, with the AI review included" }
else {
  $t = ReadText $ci
  if ($t -match 'ci/ai-review\.yml') { Ok ".gitlab-ci.yml already includes the AI review" }
  elseif ($t -match '(?m)^include:') { Warn ".gitlab-ci.yml already has an include: list - add this line to it yourself:   - local: ci/ai-review.yml" }
  else { WriteText $ci ($t + "`ninclude:`n  - local: ci/ai-review.yml`n"); Ok "AI review included in your existing .gitlab-ci.yml" }
}

Hdr "3 - Commands, templates and prompts"
foreach ($d in @(".claude\commands","prompts")) { New-Item -ItemType Directory -Force -Path (Join-Path $Repo $d) | Out-Null }
$n = 0
Get-ChildItem (Join-Path $Here "claude-commands\*.md") | ForEach-Object {
  Copy-Item $_.FullName (Join-Path $Repo ".claude\commands\") -Force; $n++
}
Ok "$n commands added to .claude/commands/"
foreach ($t in @("prompt-card","validation","spec-review")) { Add-File (Join-Path $Here "templates\$t.md") "templates\$t.md" }
Copy-Item (Join-Path $Here "prompts\11-12-ai-engineering.md"), (Join-Path $Here "prompts\spec-enhancement.md") (Join-Path $Repo "prompts\") -Force
Ok "prompts/11-12-ai-engineering.md and prompts/spec-enhancement.md added"
Add-File (Join-Path (Split-Path -Parent $Here) "lab-constraints.md") "specs\design\azure-lab-constraints.md"   # read by /azure-gaps and /azure-terraform
New-Item -ItemType Directory -Force -Path (Join-Path $Repo ".claude\infra-starter") | Out-Null
Get-ChildItem (Join-Path $Here "infra-starter") -File | ForEach-Object { Add-File $_.FullName (".claude\infra-starter\" + $_.Name) }   # the known-good Terraform shape /azure-terraform starts from
$gi = Join-Path $Repo ".gitignore"; if (-not (Test-Path $gi)) { New-Item -ItemType File $gi | Out-Null }
$raw = Get-Content -Raw $gi -ErrorAction SilentlyContinue
if ($raw -and -not $raw.EndsWith("`n")) { Add-Content -Path $gi -Value "" -NoNewline; Add-Content -Path $gi -Value "" }
$giLines = @(Get-Content $gi -ErrorAction SilentlyContinue)
foreach ($line in @('*.tfstate','*.tfstate.*','.terraform/','*.tfvars','!*.tfvars.example','.env','ai-review.json','ai-review.md','ai-review.log')) {
  if ($giLines -notcontains $line) { Add-Content -Path $gi -Value $line }
}
Ok ".gitignore keeps Terraform state, .terraform/, *.tfvars, .env and local AI review files out of git"

Hdr "4 - CLAUDE.md"
$claude = Join-Path $Repo "CLAUDE.md"
$block = ReadText (Join-Path $Here "templates\CLAUDE-layer3.md")
if (-not (Test-Path $claude)) { WriteText $claude $block; Warn "No CLAUDE.md - created one with just the layer-3 section" }
elseif ((ReadText $claude) -match '(?m)^## Layer 3') { Ok "CLAUDE.md already has the layer-3 section" }
else { WriteText $claude ((ReadText $claude) + $block); Ok "Layer-3 section added to CLAUDE.md" }

Hdr "5 - One commit"
git -C $Repo add -A
git -C $Repo diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Ok "Nothing new to commit" }
else {
  git -C $Repo commit -q -m "setup: layer 3 - AI review in the pipeline, task and validation commands"
  if ($LASTEXITCODE -eq 0) { Ok "Committed: setup: layer 3 ..." } else { Bad "Commit failed - see the message above"; exit 1 }
}

Write-Host ""
Write-Host "Next:"
Write-Host "  1. Push - on a branch if main is protected:  git -C `"$Repo`" switch -c setup/layer-3 ; git -C `"$Repo`" push -u origin setup/layer-3"
Write-Host "  2. Add the two masked CI/CD variables (README, Part A) - your group's Maintainer does this"
Write-Host "  3. Check as you go:  ./check-ai-engineering.ps1 -Path `"$Repo`""
