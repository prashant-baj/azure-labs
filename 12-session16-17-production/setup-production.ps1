# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  setup-production.ps1  -  Sessions 16 and 17, layer 6: secure, observable, ready for production -
#                           a threat model with tested controls, a scan of the running service,
#                           Application Insights with one business and one technical signal, alerts,
#                           a drill and a rollback (Windows PowerShell 5.1 / PowerShell 7)
#
#  What it does, once per group:
#    1. Adds the four layer-6 Claude Code commands and the templates
#    2. Adds ci\production.yml (verify:dast, verify:observability, the drill, rollback), included in
#       .gitlab-ci.yml; brings ci\confidence.py up to date if you never changed it
#    3. Adds infra\secrets.tf (Session 16) and infra\observability.tf.s17 (Session 17 renames it to .tf)
#    4. Starts specs\design\threat-model.md and specs\design\observability.md from the templates, and
#       copies your case's notes (case-notes\) to specs\design\threat-notes.md
#    5. Keeps scan and telemetry reports out of git (.gitignore); adds the layer-6 section to CLAUDE.md
#    6. Commits all of it as one commit, on a branch if you are on main
#
#  OBSERVABILITY stays "off" until Session 17. Never overwrites your files.
#
#  USAGE
#    ./setup-production.ps1 -Path "C:\work\group-1"
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  A bash twin (setup-production.sh) exists for macOS / Linux / WSL.
# =============================================================================
param([Parameter(Mandatory=$true)][string]$Path)

function Ok($m)   { Write-Host "  [ OK ] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red }
function Hdr($m)  { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
$Utf8 = New-Object System.Text.UTF8Encoding $false
function ReadText($p)  { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }
function WriteText($p, $t) { [System.IO.File]::WriteAllText($p, $t, $Utf8) }
function Sum($p) {   # md5 of the file with Windows line endings removed - the same on every checkout
  $bytes = $Utf8.GetBytes(((ReadText $p) -replace "`r", ''))
  $md5 = [System.Security.Cryptography.MD5]::Create()
  (($md5.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join '')
}

$Here = $PSScriptRoot
if (-not (Test-Path $Path)) { Bad "Path not found: $Path"; exit 1 }
$Repo = (Resolve-Path $Path).Path
$ci = Join-Path $Repo ".gitlab-ci.yml"

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Sessions 16-17 - set up layer 6"
Write-Host " $Repo"
Write-Host "============================================================"

Hdr "Before we start"
if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository."; exit 1 }
if (-not (Test-Path (Join-Path $Repo "ci\confidence.yml"))) { Bad "No ci/confidence.yml - layer 5 comes first (11-session14-15-confidence)"; exit 1 }
if (git -C $Repo status --porcelain) { Bad "You have uncommitted changes. Commit or stash them first, so this step is one clean commit."; exit 1 }
git -C $Repo rev-parse -q --verify refs/tags/L5-tested 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Ok "Tag L5-tested found - layer 6 starts from it" }
else { Warn "No tag L5-tested - tag what you have (git tag L5-tested; git push --tags), log the rest as debt" }
if ((ReadText (Join-Path $Repo "ci\confidence.yml")) -match '(?m)^\s*CONFIDENCE_DEPLOY:\s*"on"') { Ok "CONFIDENCE_DEPLOY is on - main deploys and verifies" }
else { Warn "CONFIDENCE_DEPLOY is not on - verify:dast needs a deployed service (Session 15, step 5)" }
$cur = (git -C $Repo rev-parse --abbrev-ref HEAD).Trim()
$def = (git -C $Repo symbolic-ref --short refs/remotes/origin/HEAD 2>$null)
$def = if ($def) { ($def -replace '^origin/', '').Trim() } else { 'main' }
if ($cur -eq $def) {
  git -C $Repo pull --ff-only --quiet 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok "$def is up to date" } else { Warn "Could not pull $def - carrying on" }
  git -C $Repo rev-parse -q --verify refs/heads/setup/layer-6 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { git -C $Repo switch --quiet setup/layer-6 2>$null; Warn "Branch setup/layer-6 already existed - switched to it" }
  else { git -C $Repo switch --quiet -c setup/layer-6 2>$null; Ok "Created branch setup/layer-6 - main is protected" }
  $cur = 'setup/layer-6'
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
Ok "$($cmds.Count) layer-6 commands added to .claude/commands/"
foreach ($t in @("threat-model.md", "observability.md")) { Add-File (Join-Path $Here "templates\$t") "templates\$t" }

Hdr "2 - The production checks in the pipeline"
Add-File (Join-Path $Here "ci\production.yml") "ci\production.yml"
$newPy = Join-Path $Here "ci\confidence.py"
$repoPy = Join-Path $Repo "ci\confidence.py"
if (-not (Test-Path $repoPy)) { Copy-Item $newPy $repoPy; Ok "ci/confidence.py added" }
else {
  $have = Sum $repoPy
  if ($have -eq (Sum $newPy)) { Ok "ci/confidence.py already reads the scan and the telemetry" }
  elseif (@('659101c48dba65b9c889c2298640d515', '3279dafc12ea73a720f4e1be7640db0d') -contains $have) {
    Copy-Item $newPy $repoPy -Force; Ok "ci/confidence.py updated - it now reads zap.json and obs.json too"
  } else {
    Copy-Item $newPy "$repoPy.new" -Force
    Warn "You changed ci/confidence.py - the new one is ci/confidence.py.new. Merge its dast.* and obs.* measures in, then delete it"
  }
}
$f = 'ci/production.yml'
if (-not (Test-Path $ci)) { WriteText $ci "include:`n  - local: $f`n"; Warn ".gitlab-ci.yml created - you had none" }
else {
  $t = ReadText $ci
  $nl = if ($t -match "`r`n") { "`r`n" } else { "`n" }
  if ($t.Contains($f)) { Ok "$f is already included" }
  elseif ($t -match '(?m)^include:[ \t]*\[(.*)\][ \t]*\r?$') { WriteText $ci ([regex]::Replace($t, '(?m)^include:[ \t]*\[(.*)\][ \t]*(?=\r?$)', "include: [`$1, { local: $f }]", 1)); Ok "$f added to your include: list" }
  elseif ($t -match '(?m)^include:[ \t]*\r?$') { WriteText $ci (([regex]'(?m)^include:[ \t]*(?=\r?$)').Replace($t, "include:$nl  - local: $f", 1)); Ok "$f added to your include: list" }
  elseif ($t -match '(?m)^include:') { Warn "Your include: is in a form this script does not edit. Add yourself:   - local: $f" }
  else { WriteText $ci ($t.TrimEnd() + "$nl$nl" + "include:$nl  - local: $f$nl"); Ok "$f included" }
}
if ((ReadText $ci) -match '(?m)^stages:.*verify|^\s*-\s*verify\s*\r?$') { Ok "stage verify found" }
else { Warn "No verify stage in .gitlab-ci.yml - setup-testing adds it; add verify after deploy" }

Hdr "3 - Terraform: secrets now, observability in Session 17"
$infra = Join-Path $Repo "infra"
if (Test-Path $infra) {
  Add-File (Join-Path $Here "infra-additions\secrets.tf") "infra\secrets.tf"
  if (Test-Path (Join-Path $infra "observability.tf")) { Ok "infra/observability.tf already exists - left alone" }
  else { Add-File (Join-Path $Here "infra-additions\observability.tf") "infra\observability.tf.s17" }
  $main = Join-Path $infra "main.tf"
  if ((Test-Path $main) -and (ReadText $main).Contains('app_secret_names')) { Ok "main.tf already hands the secrets to the Container App" }
  else { Warn "main.tf does not use the secrets yet - paste $(Join-Path $Here 'infra-additions\container-app-secrets.snippet.tf') (WORKSHOP-S16.md, step 4)" }
} else { Warn "No infra/ - Session 12's Terraform; the secrets and the observability stack live there" }

Hdr "4 - The threat model and the observability spec"
Add-File (Join-Path $Here "templates\threat-model.md") "specs\design\threat-model.md"
Add-File (Join-Path $Here "templates\observability.md") "specs\design\observability.md"
$origin = (git -C $Repo remote get-url origin 2>$null); if (-not $origin) { $origin = $Repo }
$letter = ([regex]::Matches("$origin", 'case-[a-e]') | Select-Object -Last 1).Value
$note = if ($letter) { Get-ChildItem (Join-Path $Here "case-notes") -Filter "$letter-*.md" -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 1 } else { $null }
if ($note) { Ok "Your case: $($note.BaseName) - its notes are checks for step 2"; Add-File $note.FullName "specs\design\threat-notes.md" }
else { Warn "Could not tell your case from the repo name - copy yours: cp <lab>/case-notes/case-<letter>-*.md specs/design/threat-notes.md" }

Hdr "5 - .gitignore and CLAUDE.md"
$gi = Join-Path $Repo ".gitignore"
if (-not (Test-Path $gi)) { WriteText $gi "" }
$g = ReadText $gi
if ($g.Length -gt 0 -and -not $g.EndsWith("`n")) { $g += "`n" }
$have = @($g -split "\r?\n")
foreach ($line in @('zap.json', 'zap.html', 'obs.json', 'drill-k6.json', '*.tfvars', '.env')) { if ($have -notcontains $line) { $g += "$line`n" } }
WriteText $gi $g
Ok ".gitignore keeps scan and telemetry reports, .tfvars and .env out of git"
$claude = Join-Path $Repo "CLAUDE.md"
if ((Test-Path $claude) -and ((ReadText $claude) -match '(?m)^## Layer 6')) { Ok "CLAUDE.md already has the layer-6 section" }
else {
  $old = if (Test-Path $claude) { ReadText $claude } else { "" }
  WriteText $claude ($old + (ReadText (Join-Path $Here "templates\CLAUDE-layer6.md"))); Ok "Layer-6 section added to CLAUDE.md"
}

Hdr "6 - One commit"
git -C $Repo add -A 2>$null
git -C $Repo diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Ok "Nothing new to commit" }
else {
  git -C $Repo commit -q -m "setup: layer 6 - production checks, secrets and observability Terraform, threat model and observability templates"
  if ($LASTEXITCODE -eq 0) { Ok "Committed on $cur" } else { Bad "Commit failed - see the message above"; exit 1 }
}

Write-Host ""
Write-Host "Next - step by step in $(Join-Path $Here 'WORKSHOP-S16.md'):"
Write-Host "  2. /threat-model specs/<slice>     - what could go wrong, STRIDE by STRIDE; try T-01 on your own service"
Write-Host "  3. Controls, red test first: the key, the headers, escaping - $(Join-Path $Here 'stacks.md'), sections 1 to 4"
Write-Host "  4. The secret's journey: masked APP_API_KEY in GitLab, infra/secrets.tf, the snippet into main.tf"
Write-Host "  5. Push, merge - verify:dast scans the deployed service; set the dast.* rows from what it found"
Write-Host "  Check as you go:  ./check-production.ps1 -Path `"$Repo`""
