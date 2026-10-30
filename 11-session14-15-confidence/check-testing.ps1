# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-testing.ps1  -  Sessions 14 and 15, layer 5: is the confidence automated - and measurable?
#                        A test strategy with thresholds, a suite that grew, API checks, a deploy that
#                        verifies itself, and a scorecard the pipeline decides on.
#                        (Windows PowerShell 5.1 / PowerShell 7)
#
#  Checks files, records and git history. It does not run your tests or deploy - the pipeline does that,
#  and confidence.md in each pipeline is the evidence.
#
#  USAGE
#    ./check-testing.ps1 [-Path "C:\work\group-1"]
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  Exit code is non-zero only if something required is missing.
#  A bash twin (check-testing.sh) exists for macOS / Linux / WSL.
# =============================================================================
param([string]$Path = ".")

$script:Pass = 0; $script:WarnN = 0; $script:Fail = 0; $script:Miss = 0
function Ok($m)   { Write-Host "  [ OK ] $m" -ForegroundColor Green; $script:Pass++ }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow; $script:WarnN++ }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:Fail++ }
function Hdr($m)  { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function ReadText($p) { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }
function Lines($p) { if (Test-Path $p) { @((ReadText $p) -split "`r?`n") } else { @() } }
function Count($lines, $re) { @($lines | Where-Object { $_ -match $re }).Count }

if (-not (Test-Path $Path)) { Write-Host "Path not found: $Path"; exit 1 }
$Repo = (Resolve-Path $Path).Path
$ci = Join-Path $Repo ".gitlab-ci.yml"
$cy = Join-Path $Repo "ci/confidence.yml"
$st = Join-Path $Repo "specs/design/test-strategy.md"
$cyText = if (Test-Path $cy) { ReadText $cy } else { "" }
function CfgVar($name) { $m = [regex]::Match($cyText, "(?m)^[ \t]+${name}:[ \t]*`"([^`"]*)`""); if ($m.Success) { $m.Groups[1].Value } else { "" } }
# Lines from the first line matching $start up to the next line starting "## " (both included) - like sed -n '/a/,/b/p'
function Section($lines, $start) {
  $out = @(); $on = $false
  foreach ($l in $lines) {
    if (-not $on) { if ($l -cmatch $start) { $on = $true; $out += $l } }
    else { $out += $l; if ($l -match '^## ') { break } }
  }
  ,$out
}
function GitCount($rev) {
  $n = 0
  $o = git -C $Repo grep -hcE '^\s*(async\s+)?def test_|^\s*(test|it)\(|@Test\b' $rev -- ':!*.claude/*' ':!*node_modules/*' 2>$null
  foreach ($x in @($o)) { if ("$x" -match '^\d+$') { $n += [int]$x } }
  $n
}

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Sessions 14-15 - layer 5 check"
Write-Host " $Repo"
Write-Host "============================================================"
if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository"; exit 1 }
git -C $Repo rev-parse -q --verify refs/tags/L4-behaviour 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $base = "L4-behaviour"; Ok "Layer 5 measured from tag L4-behaviour" }
else { $base = ""; Warn "No tag L4-behaviour - the suite's growth cannot be measured" }

# --- 1. Strategy -----------------------------------------------------------------------
Hdr "1 - The test strategy - and the thresholds the pipeline decides on"
$stratOk = $false; $nfrOk = $false
$stLines = Lines $st
if (Test-Path $st) {
  Ok "specs/design/test-strategy.md"
  $sec = @(); $on = $false
  foreach ($l in $stLines) { if (-not $on) { if ($l -cmatch 'What could go wrong') { $on = $true; $sec += $l } } else { $sec += $l; if ($l -cmatch '^## 2') { break } } }
  $risks = @($sec | Where-Object { $_ -match '^\|\s*[A-Za-z]' -and $_ -notmatch '^\|\s*Risk\s*\|' }).Count
  if ($risks -ge 3) { Ok "$risks risks, each with the layer that catches it" } else { Warn "$risks risk(s) - what would hurt the client most? (/test-strategy, section 1)" }
  $na = Section $stLines '[Nn]ot automated yet'
  $naBody = @($na | Select-Object -Skip 1 | Where-Object { $_ -match '[A-Za-z]{4}' -and $_ -notmatch '^## ' })
  if (((ReadText $st) -match '(?i)not automated yet') -and $naBody.Count -gt 0) { Ok "Says what is not automated yet, and why" }
  else { Warn "No 'Not automated yet, and why' - an honest gap beats a pretty pyramid" }
  $rows = @($stLines | Where-Object { $_ -match '^\|\s*CS-\d{3}\s*\|.*\|\s*(merge|deploy)\s*\|\s*$' })
  $nrows = $rows.Count
  $known = '^(tests\.pass_rate|tests\.count|coverage\.line|api\.pass_rate|e2e\.pass_rate|perf\.p95_ms|perf\.error_rate|smoke\.version|planned\.[a-z0-9_]+)$'
  $unset = 0; $badm = 0
  foreach ($r in $rows) {
    $c = $r -split '\|'
    $th = if ($c.Count -gt 4) { $c[4] } else { "" }
    $me = if ($c.Count -gt 3) { $c[3] -replace ' ', '' } else { "" }
    if ($th -notmatch '^\s*(>=|<=|=|<|>)\s*[0-9.]+') { $unset++ }
    if ($me -notmatch $known) { $badm++ }
  }
  if ($nrows -ge 5 -and $unset -eq 0 -and $badm -eq 0) { Ok "$nrows confidence thresholds, every one set"; $stratOk = $true }
  elseif ($nrows -eq 0) { Bad "No confidence thresholds (| CS-001 | ... | merge |) - the pipeline has nothing to decide on" }
  else { Warn "$nrows threshold row(s): $unset not set yet, $badm with an unknown measure - /test-strategy, section 5" }
  if (Count $rows 'coverage\.line') { Ok "Coverage is a signal" } else { Warn "No coverage.line row - coverage is not measured" }
  $perf = @($rows | Where-Object { $_ -match 'perf\.(p95_ms|error_rate)' })
  if ($perf.Count -eq 0) { Warn "No performance threshold - which NFR says how fast is fast enough?" }
  elseif ((Count $perf 'NFR-\d{3}') -eq $perf.Count) { Ok "Every performance threshold quotes an NFR"; $nfrOk = $true }
  else { Warn "A performance threshold without an NFR - a number nobody decided" }
  foreach ($m in @('api.pass_rate', 'smoke.version')) { if (-not (Count $rows $m)) { Warn "No $m row" } }
  if (Count $stLines '^## 6\.') { Ok "Section 6 draws the pipeline from the strategy" } else { Warn "No section 6 - draw the pipeline from the rows: each row, its job, real or planned (template, section 6)" }
} else { Bad "No specs/design/test-strategy.md - /test-strategy writes it (template: templates/test-strategy.md)" }

# --- 2. The suite ----------------------------------------------------------------------------
Hdr "2 - The suite grew - and reports what it proves"
$grew = $false; $cov = $false
$now = GitCount "HEAD"
if ($base) {
  $then = GitCount $base
  if ($now -gt $then) { Ok "Tests: $then at L4-behaviour, $now now"; $grew = $true }
  else { Warn "Tests: $then at L4-behaviour, $now now - the suite has not grown" }
} else { Ok "$now tests" }
$idn = @(git -C $Repo grep -hiE '(def test_|test\(|it\(|void )[^(]*(fr|nfr|rule|def|c)[_-]?[0-9]{3}' -- ':!*.claude/*' ':!*.json' ':!*node_modules/*' 2>$null).Count
if ($idn -ge 1) { Ok "$idn tests named after an ID" } else { Warn "No tests named after an ID (test_fr_004_...)" }
$testCi = @()
if (Test-Path $ci) { $testCi += Lines $ci }
Get-ChildItem (Join-Path $Repo "ci") -Filter *.yml -File -ErrorAction SilentlyContinue | Sort-Object Name |
  Where-Object { $_.Name -notin @('confidence.yml', 'quality.yml') } | ForEach-Object { $testCi += Lines $_.FullName }
if (Count $testCi 'coverage_report|^\s+coverage:') { Ok "Coverage reported in the pipeline"; $cov = $true }
else { Warn "No coverage in your test job - stacks.md, section 2" }
if (Count $testCi 'cov-report=xml|cobertura|jacoco') { Ok "Coverage written as a file the scorecard can read" }
else { Warn "No coverage XML (cobertura or jacoco) in your pipeline - CS-003 will say NOT MEASURED" }
$ain = Count (Lines (Join-Path $Repo "reviews/ai-tests.md")) '(?i)\|\s*\**(kept|changed|rejected|not needed)\**(\s*\||\s+\()'
$aiOk = $false
if ($ain -ge 1) { Ok "AI-suggested tests reviewed: $ain decision(s) in reviews/ai-tests.md"; $aiOk = $true }
else { Warn "reviews/ai-tests.md has no decisions - /suggest-tests, then log kept / changed / rejected" }

# --- 3. API checks -------------------------------------------------------------------------------
Hdr "3 - API checks - the same collection before merge and after deploy"
$apiOk = $false
$apiDir = Join-Path $Repo "tests/api"
$col = Get-ChildItem $apiDir -Filter *.postman_collection.json -File -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 1
if ($col) {
  $colText = ReadText $col.FullName
  $nt = [regex]::Matches($colText, 'pm\.test\(\\?"[^"\\]*').Count
  $nid = [regex]::Matches($colText, 'pm\.test\(\\?"(SMOKE|FR-[0-9]{3}|NFR-[0-9]{3}|C-[0-9]{3}|RULE-[0-9]{3}|DEF-[0-9]{3})').Count
  $starter = $colText -match '<path>|FR-0nn'
  $rel = "tests/api/$($col.Name)"
  if ($starter) { Warn "$rel is still the starter - /api-tests writes yours" } else { Ok "${rel}: $nt test(s)" }
  if ($nt -gt 0 -and $nid -eq $nt) { Ok "Every API test named after the ID it proves" } else { Warn "$($nt - $nid) API test(s) without an ID at the start of the name" }
  $secretRe = '(?i)"(password|token|secret|apikey|api_key)"\s*:\s*"[^"{]{6,}|"key"\s*:\s*"[^"]*(password|token|secret|apikey|api_key)[^"]*"\s*,\s*"value"\s*:\s*"[^"{]{6,}|Bearer [A-Za-z0-9._-]{20,}'
  $leak = $false
  Get-ChildItem $apiDir -Filter *.json -File | ForEach-Object { if (((ReadText $_.FullName) -replace "[`r`n]", " ") -match $secretRe) { $leak = $true } }
  if ($leak) { Bad "A secret value in tests/api/ - pass it with --env-var from a pipeline variable" } else { Ok "No secrets in the collection" }
  if ($colText.Contains('{{baseUrl}}')) { Ok "Requests use {{baseUrl}} - one collection, every environment" } else { Warn "Hard-coded URLs - use {{baseUrl}}" }
  if ($nt -ge 3 -and $nid -eq $nt -and -not $starter) { $apiOk = $true }
} else { Bad "No tests/api/*.postman_collection.json - /api-tests writes it" }
$appStart = CfgVar "APP_START"
if ($appStart) { Ok "api:local on - APP_START: $appStart" } else { Warn "APP_START is empty - api:local does not run before merge (stacks.md, section 3)" }

# --- 4. Deploy and verify (Session 15) -----------------------------------------------------------
Hdr "4 - Deploy with measurable confidence (Session 15)"
$depOk = $false; $perfOk = $false
if (Test-Path $cy) {
  if ((CfgVar "CONFIDENCE_DEPLOY") -eq "on") { Ok "CONFIDENCE_DEPLOY is on - main builds, deploys and verifies"; $depOk = $true }
  else { Warn "CONFIDENCE_DEPLOY is off - Session 15 turns it on" }
  $appd = CfgVar "APP_DIR"; if (-not $appd) { $appd = "." }
  if (Test-Path (Join-Path (Join-Path $Repo $appd) "Dockerfile")) { Ok "$appd/Dockerfile" } else { Warn "No $appd/Dockerfile - build:image needs it" }
  $inf = CfgVar "CONFIDENCE_INFRA"; if (-not $inf) { $inf = "infra" }
  $infDir = Join-Path $Repo $inf
  if (Test-Path $infDir -PathType Container) {
    $tf = (Get-ChildItem $infDir -Filter *.tf -File | ForEach-Object { ReadText $_.FullName }) -join "`n"
    $infMiss = ""
    foreach ($v in @('prefix', 'image', 'target_port')) { if ($tf -notmatch "variable\s+`"$v`"") { $infMiss += " var.$v" } }
    foreach ($o in @('acr_name', 'acr_login_server', 'app_url')) { if ($tf -notmatch "output\s+`"$o`"") { $infMiss += " output.$o" } }
    if (-not $infMiss) { Ok "$inf/ takes the image and port, and gives back the registry and the URL" } else { Warn "$inf/ is missing:$infMiss - the Session 12 starter has them" }
  } else { Warn "No $inf/ - deploy:test applies it" }
}
$smoke = Join-Path $Repo "tests/perf/smoke.js"
if (Test-Path $smoke) {
  $sm = ReadText $smoke
  $th = $sm -match 'thresholds'
  if ($th) { Ok "tests/perf/smoke.js has thresholds" } else { Warn "tests/perf/smoke.js has no thresholds - then it measures, but never decides" }
  if ($sm.Contains("PERF_PATHS || '/health'")) { Warn "The perf smoke only calls /health - point it at the answer your NFR is about" }
  elseif ($th) { $perfOk = $true }
} else { Warn "No tests/perf/smoke.js" }
if (Test-Path (Join-Path $Repo "tests/e2e/package.json")) {
  $ne = 0
  Get-ChildItem (Join-Path $Repo "tests/e2e/tests") -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $ne += [regex]::Matches((ReadText $_.FullName), "test\(['`"]").Count }
  Ok "tests/e2e/: $ne journey(s)"; if ($ne -gt 5) { Warn "More than five end-to-end journeys - keep these few; push the rest down" }
} else {
  if (Count (Section $stLines '[Nn]ot automated yet') '(?i)\b(end.to.end|e2e|UI)\b') { Ok "No tests/e2e/ - and the strategy says why" }
  else { Warn "No tests/e2e/ - if you have a web UI, copy .claude/test-starters/e2e; if not, say so in the strategy" }
}
$defs = @(Get-ChildItem (Join-Path $Repo "specs/design/defects") -Filter "DEF-*.md" -File -ErrorAction SilentlyContinue)
if ($defs.Count -gt 0) { Ok "Defect analyses: $($defs.Count)" }

# --- 5. The pipeline -------------------------------------------------------------------------------
Hdr "5 - The pipeline"
$pipeOk = $false
if (Test-Path (Join-Path $Repo "ci/confidence.py")) { Ok "ci/confidence.py - the scorecard" } else { Bad "No ci/confidence.py - setup-testing adds it" }
$ciLines = Lines $ci
if ((Test-Path $ci) -and (Count $ciLines 'ci/confidence\.yml')) { Ok "ci/confidence.yml included"; $pipeOk = $true } else { Bad "ci/confidence.yml not included in .gitlab-ci.yml" }
if (Test-Path $ci) {
  $i = -1; for ($k = 0; $k -lt $ciLines.Count; $k++) { if ($ciLines[$k] -cmatch '^stages:') { $i = $k; break } }
  if ($i -ge 0) {
    $sl = @($ciLines[$i])
    for ($k = $i + 1; $k -lt $ciLines.Count; $k++) { $sl += $ciLines[$k]; if ($ciLines[$k] -match '^[^\s#-]') { break } }
    $tokens = @((($sl -join ' ') -replace '[\[\],-]', ' ') -split '\s+' | Where-Object { $_ })
    foreach ($s in @('check', 'test', 'deploy', 'verify')) { if ($tokens -cnotcontains $s) { Bad "stage '$s' missing from stages:"; $pipeOk = $false } }
    if ($pipeOk) { Ok "stages: check, test, deploy, verify" }
  } else { Bad "No stages: list in .gitlab-ci.yml - check, test, deploy and verify must be in it"; $pipeOk = $false }
}
if (Test-Path (Join-Path $Repo "ci/quality.yml")) { Ok "Session 13 quality gates still in the pipeline" } else { Warn "No ci/quality.yml - the gates from Session 13" }
$mapOk = $false
if ((Test-Path $cy) -and (Test-Path $st)) {
  $meas = @($rows | ForEach-Object { $c = $_ -split '\|'; if ($c.Count -gt 3) { $c[3] -replace ' ', '' } })
  $planned = @([regex]::Matches($cyText, '(?m)^"([a-z0-9:_-]+) \(planned\)":') | ForEach-Object { $_.Groups[1].Value })
  $mm = 0
  $pm = @{ 'verify:smoke' = @('smoke.version'); 'verify:api' = @('api.pass_rate'); 'verify:e2e' = @('e2e.pass_rate'); 'verify:perf' = @('perf.p95_ms', 'perf.error_rate') }
  if ((CfgVar "CONFIDENCE_DEPLOY") -ne "on") {
    foreach ($j in @('verify:smoke', 'verify:api', 'verify:e2e', 'verify:perf')) {
      $rowHas = @($pm[$j] | Where-Object { $meas -contains $_ }).Count -gt 0
      $jobHas = $planned -contains $j
      if ($rowHas -and -not $jobHas) { Warn "A row needs $j, but its (planned) job is gone - it will not show in today's pipeline"; $mm++ }
      if (-not $rowHas -and $jobHas) { Warn "`"$j (planned)`" has no row in the strategy - add the row, or delete the job and say why under 'Not automated yet'"; $mm++ }
    }
  }
  $ciAll = (@($cy, $ci) + @(Get-ChildItem (Join-Path $Repo "ci") -Filter *.yml -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })) | Where-Object { Test-Path $_ } | ForEach-Object { ReadText $_ }
  foreach ($m in $meas) { if ($m -like 'planned.*') { if (-not (($ciAll -join "`n").Contains($m))) { Warn "Row $m has no (planned) job - copy one in ci/confidence.yml and set PLANNED_MEASURE: `"$m`""; $mm++ } } }
  if ($mm -eq 0) { Ok "Every row has a job, every job a row - $($planned.Count) planned job(s) mark what is not built yet"; $mapOk = $true }
}
git -C $Repo rev-parse -q --verify refs/tags/L5-tested 2>$null | Out-Null
$tagged = ($LASTEXITCODE -eq 0)

Hdr "Ready for layer 6? (see BUILD-ROADMAP.md)"
function Bar($yes, $m) { if ($yes) { Write-Host "  [ HAVE ] $m" -ForegroundColor Green } else { Write-Host "  [ NEED ] $m" -ForegroundColor Red; $script:Miss++ } }
Bar $stratOk "A test strategy with every confidence threshold set"
Bar $nfrOk "Performance thresholds that quote an NFR"
Bar ($grew -and $cov) "A suite that grew, with coverage reported"
Bar $apiOk "API checks written from the spec, named after their IDs"
Bar $aiOk "AI-suggested tests reviewed and logged"
Bar $pipeOk "The confidence pipeline included, stages in place"
Bar $mapOk "The pipeline drawn from the strategy - every row a job, real or planned"
Bar ($depOk -and $perfOk) "Deploy on: build once, deploy, verify, decide (Session 15)"
Bar $tagged "Tagged L5-tested"
Write-Host ""
if ($script:Miss -eq 0) { Write-Host "  READY - layer 5 is in. Every merge deploys, with a scorecard you can show." -ForegroundColor Green }
else { Write-Host "  NOT YET - $($script:Miss) item(s) above." -ForegroundColor Yellow }

Write-Host ""
Write-Host "============================================================"
Write-Host " ok: $($script:Pass)   warnings: $($script:WarnN)   failed: $($script:Fail)"
Write-Host "============================================================"
if ($script:Fail -gt 0) { Write-Host " Something required is missing. Fix the [FAIL] lines and run again."; exit 1 }
if ($script:WarnN -gt 0) { Write-Host " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them." }
exit 0
