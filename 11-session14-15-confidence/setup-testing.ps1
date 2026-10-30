# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  setup-testing.ps1  -  Sessions 14 and 15, layer 5: automate the confidence - a test strategy with
#                        measurable thresholds, a growing suite, API, performance and end-to-end checks,
#                        and a pipeline that deploys and decides (Windows PowerShell 5.1 / PowerShell 7)
#
#  What it does, once per group:
#    1. Adds the four layer-5 Claude Code commands and the templates
#    2. Adds ci\confidence.py (the scorecard) and ci\confidence.yml for your stack, included in
#       .gitlab-ci.yml; makes sure the stages check, test, deploy and verify exist
#    3. Starts tests\api\ (a Postman collection) and tests\perf\smoke.js (a k6 smoke) - if you have none
#    4. Starts specs\design\test-strategy.md from the template - /test-strategy fills it
#    5. Keeps reports and pipeline-only files out of git (.gitignore); adds the layer-5 section to CLAUDE.md
#    6. Commits all of it as one commit, on a branch if you are on main
#
#  The deploy half stays OFF (CONFIDENCE_DEPLOY: "off") until Session 15. Never overwrites your files.
#
#  USAGE
#    ./setup-testing.ps1 -Path "C:\work\group-1" [-Stack python|node|java] [-App <app folder>]
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  A bash twin (setup-testing.sh) exists for macOS / Linux / WSL.
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
Write-Host " Junior SWAT Labs - Sessions 14-15 - set up layer 5"
Write-Host " $Repo"
Write-Host "============================================================"

Hdr "Before we start"
if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository."; exit 1 }
if (-not (Test-Path (Join-Path $Repo "constitution.md"))) { Bad "No constitution.md - layers 1 to 4 come first"; exit 1 }
if (git -C $Repo status --porcelain) { Bad "You have uncommitted changes. Commit or stash them first, so this step is one clean commit."; exit 1 }
git -C $Repo rev-parse -q --verify refs/tags/L4-behaviour 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Ok "Tag L4-behaviour found - layer 5 starts from it" }
else { Warn "No tag L4-behaviour - tag what you have (git tag L4-behaviour; git push --tags), log the rest as debt" }
$cur = (git -C $Repo rev-parse --abbrev-ref HEAD).Trim()
$def = (git -C $Repo symbolic-ref --short refs/remotes/origin/HEAD 2>$null)
$def = if ($def) { ($def -replace '^origin/', '').Trim() } else { 'main' }
if ($cur -eq $def) {
  git -C $Repo pull --ff-only --quiet 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok "$def is up to date" } else { Warn "Could not pull $def - carrying on" }
  git -C $Repo rev-parse -q --verify refs/heads/setup/layer-5 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { git -C $Repo switch --quiet setup/layer-5 2>$null; Warn "Branch setup/layer-5 already existed - switched to it" }
  else { git -C $Repo switch --quiet -c setup/layer-5 2>$null; Ok "Created branch setup/layer-5 - main is protected" }
  $cur = 'setup/layer-5'
} else { Ok "Working on branch $cur" }
if (Test-Path (Join-Path $Repo "ci\quality.yml")) { Ok "Session 13 quality gates found (ci/quality.yml)" } else { Warn "No ci/quality.yml - Session 13's quality gates come first (10-session13-quality)" }

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
Ok "$($cmds.Count) layer-5 commands added to .claude/commands/"
foreach ($t in @("test-strategy.md", "ai-tests-review.md", "defect-analysis.md")) { Add-File (Join-Path $Here "templates\$t") "templates\$t" }

Hdr "2 - Your stack"
if (-not $Stack -or -not $App) {
  $skip = '[\\/](node_modules|\.git|\.claude|specs|target|\.venv|tests)([\\/]|$)'
  $found = @(Get-ChildItem $Repo -Recurse -Depth 2 -File -Include pom.xml, package.json, pyproject.toml, requirements.txt -ErrorAction SilentlyContinue |
             Where-Object { $_.FullName.Substring($Repo.Length) -notmatch $skip })
  foreach ($cand in @(@('java', 'pom.xml'), @('node', 'package.json'), @('python', 'pyproject.toml'), @('python', 'requirements.txt'))) {
    if ($Stack -and $Stack -ne $cand[0]) { continue }
    $hit = $found | Where-Object { $_.Name -eq $cand[1] } | Sort-Object { ($_.FullName.Substring($Repo.Length) -split '[\\/]').Count } | Select-Object -First 1
    if (-not $hit) { continue }
    $Stack = $cand[0]
    if (-not $App) { $rel = $hit.DirectoryName.Substring($Repo.Length).TrimStart('\', '/') -replace '\\', '/'; $App = if ($rel) { $rel } else { '.' } }
    break
  }
}
if (-not $App) { $App = '.' }
if (-not $Stack) { Bad "Could not tell your stack. Run again with -Stack python|node|java -App <folder>"; exit 1 }
Ok "Stack: $Stack, app folder: $App"
if (Test-Path (Join-Path $Repo "$App\Dockerfile")) { Ok "$App/Dockerfile found - build:image will use it" } else { Warn "No $App/Dockerfile - Session 12 wrote one; build:image needs it in Session 15" }
if (Test-Path (Join-Path $Repo "infra")) { Ok "infra/ found - deploy:test will apply it" } else { Warn "No infra/ - Session 12's Terraform; deploy:test needs it in Session 15" }

Hdr "3 - The confidence pipeline"
New-Item -ItemType Directory -Force -Path (Join-Path $Repo "ci") | Out-Null
Add-File (Join-Path $Here "ci\confidence.py") "ci\confidence.py"
$cy = Join-Path $Repo "ci\confidence.yml"
if (Test-Path $cy) { Ok "ci/confidence.yml already exists - left alone" }
else {
  WriteText $cy ((ReadText (Join-Path $Here "ci\confidence-$Stack.yml")) -replace 'APP_DIR: "\." ', "APP_DIR: `"$App`" ")
  Ok "ci/confidence.yml added - $Stack, app folder $App. Deploy half OFF until Session 15"
}
$f = 'ci/confidence.yml'
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

# stages - the order matters: build, check, test, deploy, verify. Missing ones go in their place.
$want = @('build', 'check', 'test', 'deploy', 'verify')
$t = ReadText $ci
$nl = if ($t -match "`r`n") { "`r`n" } else { "`n" }
if ($t -notmatch '(?m)^stages:') {
  $lines = [Collections.Generic.List[string]]($t -split "\r?\n")
  $at = if ($lines.Count -gt 0 -and $lines[0].StartsWith('#')) { 1 } else { 0 }
  $lines.Insert($at, ""); $lines.Insert($at, "stages: [build, check, test, deploy, verify]")
  WriteText $ci ($lines -join $nl); Ok "stages: [build, check, test, deploy, verify] added"
} else {
  $inline = $t -match '(?m)^stages:[ \t]*\[([^\]]*)\]'
  if ($inline) { $have = @($Matches[1] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
  else {
    $have = @(); $in = $false
    foreach ($l in ($t -split "\r?\n")) {
      if ($l -match '^stages:') { $in = $true; continue }
      if ($in) { if ($l -match '^\s*-\s*([A-Za-z0-9_.-]+)') { $have += $Matches[1] } else { break } }
    }
  }
  $new = [Collections.Generic.List[string]]$have
  foreach ($s in $want) {
    if ($new.Contains($s) -or $s -eq 'build') { continue }
    $prev = $null; foreach ($w in $want) { if ($w -eq $s) { break }; if ($new.Contains($w)) { $prev = $w } }
    if ($prev) { $new.Insert($new.IndexOf($prev) + 1, $s) } else { $new.Insert(0, $s) }
  }
  if (($new -join ' ') -ne ($have -join ' ')) {
    if ($inline) { WriteText $ci ([regex]::Replace($t, '(?m)^stages:[ \t]*\[[^\]]*\]', ('stages: [' + ($new -join ', ') + ']'), 1)) }
    else {
      $out = New-Object System.Collections.Generic.List[string]; $in = $false
      foreach ($l in ($t -split "\r?\n")) {
        if ($l -match '^stages:') { $out.Add($l); foreach ($s in $new) { $out.Add("  - $s") }; $in = $true; continue }
        if ($in -and $l -match '^\s*-') { continue }
        $in = $false; $out.Add($l)
      }
      WriteText $ci ($out -join $nl)
    }
    Ok "stages: now  $($new -join ' ')"
  } else { Ok "stages: already has check, test, deploy, verify" }
}

Hdr "4 - Test suites and the strategy"
Add-File (Join-Path $Here "starters\api\local.postman_environment.json") "tests\api\local.postman_environment.json"
if (Get-ChildItem (Join-Path $Repo "tests\api") -Filter *.postman_collection.json -ErrorAction SilentlyContinue) { Ok "tests/api/ already has a collection - left alone" }
else { Add-File (Join-Path $Here "starters\api\starter.postman_collection.json") "tests\api\$(Split-Path $Repo -Leaf).postman_collection.json" }
Add-File (Join-Path $Here "starters\perf\smoke.js") "tests\perf\smoke.js"
$ts = Join-Path $Repo ".claude\test-starters"
New-Item -ItemType Directory -Force -Path $ts | Out-Null
Copy-Item (Join-Path $Here "starters\e2e") $ts -Recurse -Force
Ok ".claude/test-starters/e2e - a Playwright starter, if you have a web UI (README, Session 15)"
Add-File (Join-Path $Here "templates\test-strategy.md") "specs\design\test-strategy.md"
Add-File (Join-Path $Here "templates\ai-tests-review.md") "reviews\ai-tests.md"

Hdr "5 - .gitignore and CLAUDE.md"
$gi = Join-Path $Repo ".gitignore"
$g = if (Test-Path $gi) { ReadText $gi } else { "" }
$haveLines = @($g -split "\r?\n")
$add = @('newman*.xml', 'k6-summary.json', 'confidence.md', 'confidence.json', 'health.json', 'app.log', 'ci_backend_override.tf',
         'tests/e2e/node_modules/', 'tests/e2e/test-results/', 'tests/e2e/playwright-report/', 'e2e.xml') | Where-Object { $haveLines -notcontains $_ }
if ($add) { if ($g -and -not $g.EndsWith("`n")) { $g += "`n" }; WriteText $gi ($g + (($add -join "`n") + "`n")) }
Ok ".gitignore keeps reports and pipeline-only files out of git"
$cm = Join-Path $Repo "CLAUDE.md"
if ((Test-Path $cm) -and ((ReadText $cm) -match '(?m)^## Layer 5')) { Ok "CLAUDE.md already has the layer-5 section" }
else { $old = if (Test-Path $cm) { ReadText $cm } else { "" }; WriteText $cm ($old + (ReadText (Join-Path $Here "templates\CLAUDE-layer5.md"))); Ok "Layer-5 section added to CLAUDE.md" }

Hdr "6 - One commit"
git -C $Repo add -A
git -C $Repo diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Ok "Nothing new to commit" }
else {
  git -C $Repo commit -q -m "setup: layer 5 - confidence pipeline, test starters, strategy template, testing commands"
  if ($LASTEXITCODE -eq 0) { Ok "Committed on $cur" } else { Bad "Commit failed - see the message above"; exit 1 }
}

Write-Host ""
Write-Host "Next - step by step in $Here\WORKSHOP-S14.md:"
Write-Host "  2. Make your code measurable: test reports, /health with version, APP_START - $Here\stacks.md"
Write-Host "  3. Measure today:  python ci/confidence.py --when merge   (from the repo root, after your tests ran)"
Write-Host "  4. /test-strategy specs/<slice>    - risks, layers, thresholds from what you measured"
Write-Host "  5. Draw the whole pipeline: section 6 of the strategy, then ci/confidence.yml - real and (planned) jobs"
Write-Host "  6. Push:  git -C `"$Repo`" push -u origin $cur -o merge_request.create -o merge_request.target=$def"
Write-Host "  Check as you go:  ./check-testing.ps1 -Path `"$Repo`""
