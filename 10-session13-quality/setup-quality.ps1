# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  setup-quality.ps1  -  Session 13, layer 4: quality gates in your workspace and in the pipeline;
#                        stories, executable scenarios tagged with IDs, the rule built test-first
#                        (Windows PowerShell 5.1 / PowerShell 7)
#
#  What it does, once per group:
#    1. Adds the seven layer-4 Claude Code commands and the templates
#    2. Finds your stack, keeps a runnable BDD starter for it in .claude\bdd-starter\ (the commands read it)
#    3. The baseline pipeline: ci\quality.yml (lint, complexity, secrets, SAST, dependencies, IaC) and
#       ci\scenarios.yml for your stack, both included in .gitlab-ci.yml; the stages check and test
#    4. Creates specs\<your slice>\features\ - the scenarios live next to the spec
#    5. Keeps local scan output out of git (.gitignore)
#    6. Adds the layer-4 section to CLAUDE.md
#    7. Commits all of it as one commit, on a branch if you are on main
#
#  It never deletes anything, and never overwrites a file you have written. It does not touch your
#  build files (pyproject.toml, package.json, pom.xml) - stacks\<stack>\README.md says what to add.
#
#  USAGE
#    ./setup-quality.ps1 -Path "C:\work\group-1" [-Stack python|node|java] [-App <app folder>]
#    (stack and app folder are found for you; give them only if it guesses wrong)
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  A bash twin (setup-quality.sh) exists for macOS / Linux / WSL.
# =============================================================================
param(
  [Parameter(Mandatory=$true)][string]$Path,
  [ValidateSet('', 'python', 'node', 'java')][string]$Stack = '',
  [string]$App = ''
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
$ci = Join-Path $Repo ".gitlab-ci.yml"

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Session 13 - set up layer 4"
Write-Host " $Repo"
Write-Host "============================================================"

Hdr "Before we start"
if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository."; exit 1 }
if (-not (Test-Path (Join-Path $Repo "constitution.md"))) { Bad "No constitution.md - layers 1 to 3 come first"; exit 1 }
if (git -C $Repo status --porcelain) { Bad "You have uncommitted changes. Commit or stash them first, so this step is one clean commit."; exit 1 }
git -C $Repo rev-parse -q --verify refs/tags/L3-working 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Ok "Tag L3-working found - layer 4 starts from it" }
else { Warn "No tag L3-working - tag what works now (git tag L3-working; git push --tags), log the rest as debt" }
$cur = (git -C $Repo rev-parse --abbrev-ref HEAD).Trim()
$def = (git -C $Repo symbolic-ref --short refs/remotes/origin/HEAD 2>$null)
$def = if ($def) { ($def -replace '^origin/', '').Trim() } else { 'main' }
if ($cur -eq $def) {
  git -C $Repo pull --ff-only --quiet 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok "$def is up to date" } else { Warn "Could not pull $def - carrying on" }
  git -C $Repo rev-parse -q --verify refs/heads/setup/layer-4 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { git -C $Repo switch --quiet setup/layer-4 2>$null; Warn "Branch setup/layer-4 already existed - switched to it" }
  else { git -C $Repo switch --quiet -c setup/layer-4 2>$null; Ok "Created branch setup/layer-4 - main is protected" }
  $cur = 'setup/layer-4'
} else { Ok "Working on branch $cur" }
$slice = Get-ChildItem (Join-Path $Repo "specs") -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d{3}-' } | Sort-Object Name | Select-Object -Last 1
if (-not $slice) { Bad "No slice folder specs\NNN-<name>\ - layer 1 comes first"; exit 1 }
Ok "Slice: specs/$($slice.Name)"

function Add-File($src, $rel) {   # never overwrites
  $dst = Join-Path $Repo $rel
  if (Test-Path $dst) { Ok "$rel already exists - left alone"; return }
  New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
  Copy-Item $src $dst; Ok "$rel added"
}

Hdr "1 - Commands and templates"
$cmdDir = Join-Path $Repo ".claude\commands"
New-Item -ItemType Directory -Force -Path $cmdDir | Out-Null
$cmds = @(Get-ChildItem (Join-Path $Here "claude-commands") -Filter *.md)
$cmds | ForEach-Object { Copy-Item $_.FullName $cmdDir -Force }
Ok "$($cmds.Count) layer-4 commands added to .claude/commands/"
foreach ($t in @("stories.md", "example-map.md", "scenario.feature", "tdd-log.md", "quality-gates.md")) { Add-File (Join-Path $Here "templates\$t") "templates\$t" }

Hdr "2 - Your stack"
if (-not $Stack -or -not $App) {
  $skip = '[\\/](node_modules|\.git|\.claude|specs|target|\.venv)([\\/]|$)'
  $found = @(Get-ChildItem $Repo -Recurse -Depth 2 -File -Include pom.xml, package.json, pyproject.toml, requirements.txt -ErrorAction SilentlyContinue |
             Where-Object { $_.FullName.Substring($Repo.Length) -notmatch $skip })
  foreach ($cand in @(@('java', 'pom.xml'), @('node', 'package.json'), @('python', 'pyproject.toml'), @('python', 'requirements.txt'))) {
    if ($Stack -and $Stack -ne $cand[0]) { continue }
    $hit = $found | Where-Object { $_.Name -eq $cand[1] } | Sort-Object { ($_.FullName.Substring($Repo.Length) -split '[\\/]').Count } | Select-Object -First 1
    if (-not $hit) { continue }
    $Stack = $cand[0]
    if (-not $App) {
      $rel = $hit.DirectoryName.Substring($Repo.Length).TrimStart('\', '/') -replace '\\', '/'
      $App = if ($rel) { $rel } else { '.' }
    }
    break
  }
  $kinds = @($found | ForEach-Object { switch ($_.Name) { 'pom.xml' { 'java' } 'package.json' { 'node' } default { 'python' } } } | Sort-Object -Unique)
  if ($kinds.Count -gt 1 -and $Stack) { Warn "Build files for more than one stack ($($kinds -join ' ')) - chose $Stack. Wrong? Run again with -Stack and -App" }
}
if (-not $App) { $App = '.' }
if ($Stack) {
  Ok "Stack: $Stack, app folder: $App"
  $starter = Join-Path $Here "stacks\$Stack"
  $dest = Join-Path $Repo ".claude\bdd-starter"
  Get-ChildItem $starter -Recurse -File | Where-Object { $_.FullName -notmatch '[\\/](node_modules|target)[\\/]' } | ForEach-Object {
    $rel = $_.FullName.Substring($starter.Length).TrimStart('\', '/')
    $to = Join-Path $dest $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $to -Parent) | Out-Null
    Copy-Item $_.FullName $to -Force
  }
  Ok ".claude/bdd-starter/ - a runnable $Stack example the commands copy the wiring from"
} else { Warn "Could not tell your stack - no pom.xml, package.json, pyproject.toml or requirements.txt. Run again with -Stack python|node|java -App <folder>" }

Hdr "3 - The baseline pipeline - quality gates and scenarios"
function Include-Ci($f) {   # adds ci/<file>.yml to .gitlab-ci.yml in whatever include: form you have
  if (-not (Test-Path $ci)) { WriteText $ci "include:`n  - local: $f`n"; Warn ".gitlab-ci.yml created - you had none; add your test job too"; return }
  $t = ReadText $ci
  $nl = if ($t -match "`r`n") { "`r`n" } else { "`n" }
  if ($t.Contains($f)) { Ok "$f is already included" }
  elseif ($t -match '(?m)^include:[ \t]*\[(.*)\][ \t]*\r?$') {
    WriteText $ci ([regex]::Replace($t, '(?m)^include:[ \t]*\[(.*)\][ \t]*(?=\r?$)', "include: [`$1, { local: $f }]", 1)); Ok "$f added to your include: list"
  }
  elseif ($t -match '(?m)^include:[ \t]*\r?$') {
    WriteText $ci (([regex]'(?m)^include:[ \t]*(?=\r?$)').Replace($t, "include:$nl  - local: $f", 1)); Ok "$f added to your include: list"
  }
  elseif ($t -match '(?m)^include:') { Warn "Your include: is in a form this script does not edit. Add yourself:   - local: $f" }
  else { WriteText $ci ($t.TrimEnd() + "$nl$nl" + "include:$nl  - local: $f$nl"); Ok "$f included" }
}
if ($Stack) {
  New-Item -ItemType Directory -Force -Path (Join-Path $Repo "ci") | Out-Null
  $qy = Join-Path $Repo "ci\quality.yml"
  if (Test-Path $qy) { Ok "ci/quality.yml already exists - left alone" }
  else {
    WriteText $qy ((ReadText (Join-Path $Here "ci\quality-$Stack.yml")) -replace 'QA_APP_DIR: "\." ', "QA_APP_DIR: `"$App`" ")
    Ok "ci/quality.yml added - lint, complexity, secrets, SAST, dependencies, IaC for $Stack"
  }
  $sc = Join-Path $Repo "ci\scenarios.yml"
  if (Test-Path $sc) { Ok "ci/scenarios.yml already exists - left alone" }
  else {
    WriteText $sc ((ReadText (Join-Path $Here "ci\scenarios-$Stack.yml")) -replace 'APP_DIR: "\." ', "APP_DIR: `"$App`" ")
    Ok "ci/scenarios.yml added - the $Stack scenarios job, app folder $App"
  }
  Include-Ci 'ci/quality.yml'
  Include-Ci 'ci/scenarios.yml'
  # stages: the gates need `check` before `test`. No stages: list means GitLab's defaults - no `check`.
  $t = ReadText $ci
  $nl = if ($t -match "`r`n") { "`r`n" } else { "`n" }
  if ($t -notmatch '(?m)^stages:') {
    $lines = [Collections.Generic.List[string]]($t -split "\r?\n")
    $at = if ($lines.Count -gt 0 -and $lines[0].StartsWith('#')) { 1 } else { 0 }
    $lines.Insert($at, ""); $lines.Insert($at, "stages: [build, check, test, deploy]")
    WriteText $ci ($lines -join $nl); Ok "stages: [build, check, test, deploy] added - GitLab's defaults have no 'check'"
  }
  elseif ($t -match '(?m)^stages:[ \t]*\[([^\]]*)\]') {
    $items = [Collections.Generic.List[string]]@($Matches[1] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $before = $items -join ','
    if (-not $items.Contains('test')) { $items.Add('test') }
    if (-not $items.Contains('check')) { $items.Insert(0, 'check') }
    if (($items -join ',') -ne $before) {
      WriteText $ci ([regex]::Replace($t, '(?m)^stages:[ \t]*\[[^\]]*\]', ('stages: [' + ($items -join ', ') + ']'), 1)); Ok "stages: now  [$($items -join ', ')]"
    } else { Ok "stages: has check and test" }
  }
  else {
    $lines = [Collections.Generic.List[string]]($t -split "\r?\n")
    $start = -1; for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^stages:') { $start = $i; break } }
    $end = $start; $have = @()
    for ($i = $start + 1; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*-\s*([A-Za-z0-9_.-]+)') { $have += $Matches[1]; $end = $i } else { break } }
    if ($have -notcontains 'test') { $end++; $lines.Insert($end, "  - test"); Ok "stage test added to stages:" }
    if ($have -notcontains 'check') { $lines.Insert($start + 1, "  - check"); Ok "stage check added first in stages:" }
    WriteText $ci ($lines -join $nl); Ok "stages: has check and test"
  }
  $t = ReadText $ci
  foreach ($j in @('lint', 'secrets')) {
    if ($t -match "(?m)^${j}:") { Warn "Your .gitlab-ci.yml has the Session 10 job '${j}:' - qa:$j replaces it. Delete '${j}:' in this merge request" }
  }
}

Hdr "4 - Scenarios live with the spec"
$feat = Join-Path $slice.FullName "features"
New-Item -ItemType Directory -Force -Path $feat | Out-Null
if (-not (Get-ChildItem $feat -Force)) {
  WriteText (Join-Path $feat "README.md") ("# Scenarios for $($slice.Name)`n`nOne ``.feature`` file per story, written with ``/spec-scenarios``. Every scenario tagged with the IDs it`nproves (``@FR-0nn``, ``@RULE-0nn``). Start from ``templates/scenario.feature``.`n")
  Ok "specs/$($slice.Name)/features/ created"
} else { Ok "specs/$($slice.Name)/features/ already has files" }

Hdr "5 - .gitignore - local scan output stays local"
$gi = Join-Path $Repo ".gitignore"
$g = if (Test-Path $gi) { ReadText $gi } else { "" }
$haveLines = @($g -split "
?
")
$add = @('.quality/', 'gl-code-quality.json', 'gl-sast-report.json', 'scenarios.xml') | Where-Object { $haveLines -notcontains $_ }
if ($add) { if ($g -and -not $g.EndsWith("`n")) { $g += "`n" }; WriteText $gi ($g + (($add -join "`n") + "`n")) }
Ok ".gitignore keeps .quality/ and the scan reports out of git"

Hdr "6 - CLAUDE.md"
$cm = Join-Path $Repo "CLAUDE.md"
if ((Test-Path $cm) -and ((ReadText $cm) -match '(?m)^## Layer 4')) { Ok "CLAUDE.md already has the layer-4 section" }
else {
  $old = if (Test-Path $cm) { ReadText $cm } else { "" }
  WriteText $cm ($old + (ReadText (Join-Path $Here "templates\CLAUDE-layer4.md"))); Ok "Layer-4 section added to CLAUDE.md"
}

Hdr "7 - One commit"
git -C $Repo add -A
git -C $Repo diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Ok "Nothing new to commit" }
else {
  git -C $Repo commit -q -m "setup: layer 4 - quality gates and scenarios in the pipeline; stories, scenarios, TDD and quality commands"
  if ($LASTEXITCODE -eq 0) { Ok "Committed on $cur" } else { Bad "Commit failed - see the message above"; exit 1 }
}

Write-Host ""
Write-Host "Next:"
Write-Host "  1. Wire the runner into your build: $Here\stacks\$(if ($Stack) { $Stack } else { '<stack>' })\README.md  ('Wire it into your repo')"
Write-Host "  2. Push and open the merge request:  git -C `"$Repo`" push -u origin $cur -o merge_request.create -o merge_request.target=$def"
Write-Host "  3. Scan locally:  ./quality-local.ps1 -Path `"$Repo`"   then /quality-gates and /triage-findings (README, Part B)"
Write-Host "  4. Then the behaviour: /example-map, /spec-stories, /spec-scenarios, /tdd-cycle"
Write-Host "  5. Check as you go:  ./check-quality.ps1 -Path `"$Repo`""
