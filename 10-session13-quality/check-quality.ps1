# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-quality.ps1  -  Session 13, layer 4: is the behaviour proved, and is the quality bar set?
#                        Stories with acceptance criteria, the spec changed first, scenarios tagged
#                        with IDs, the rule built test-first, quality gates in the spec and the pipeline.
#                        (Windows PowerShell 5.1 / PowerShell 7)
#
#  Checks structure, records and git history - never whether a scenario is a good one.
#  It does not run your tests: the pipeline does that, on every push.
#
#  USAGE
#    ./check-quality.ps1 [-Path "C:\work\group-1"] [-Slice specs\001-name]
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  Exit code is non-zero only if something required is missing.
#  A bash twin (check-quality.sh) exists for macOS / Linux / WSL.
# =============================================================================
param([string]$Path = ".", [string]$Slice = "")

$script:Pass = 0; $script:WarnN = 0; $script:Fail = 0
function Ok($m)   { Write-Host "  [ OK ] $m" -ForegroundColor Green; $script:Pass++ }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow; $script:WarnN++ }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:Fail++ }
function Hdr($m)  { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function ReadText($p) { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }
function Ids($text) { @([regex]::Matches($text, '\b(FR|NFR|RULE)-\d{3}[a-z]?\b') | ForEach-Object { $_.Value } | Sort-Object -Unique) }

if (-not (Test-Path $Path)) { Write-Host "Path not found: $Path"; exit 1 }
$Repo = (Resolve-Path $Path).Path
if ($Slice) {
  $sd = Join-Path $Repo $Slice; if (-not (Test-Path $sd)) { $sd = Join-Path $Repo "specs\$Slice" }
} else {
  $s = Get-ChildItem (Join-Path $Repo "specs") -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d{3}-' } | Sort-Object Name | Select-Object -Last 1
  $sd = if ($s) { $s.FullName } else { "" }
}
$spec = if ($sd) { Join-Path $sd "spec.md" } else { "" }
$stories = if ($sd) { Join-Path $sd "stories.md" } else { "" }
$ci = Join-Path $Repo ".gitlab-ci.yml"

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Session 13 - layer 4 check"
Write-Host " $Repo"
Write-Host "============================================================"
if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository"; exit 1 }
if (-not $spec -or -not (Test-Path $spec)) { Bad "No slice spec found (specs/NNN-name/spec.md)"; exit 1 }
$sliceName = Split-Path $sd -Leaf
$specRel = "specs/$sliceName/spec.md"
Ok "Slice: specs/$sliceName"
git -C $Repo rev-parse -q --verify refs/tags/L3-working 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $range = "L3-working..HEAD"; Ok "Layer 4 measured from tag L3-working" }
else { $range = "HEAD"; Warn "No tag L3-working - measuring the whole history instead" }

$specText = ReadText $spec
$ids = Ids $specText
$ruleRows = @([regex]::Matches($specText, '(?m)^\|\s*(RULE-\d{3}[a-z])\s*\|') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
$frs = @([regex]::Matches($specText, '(?m)^\|\s*(FR-\d{3})\s*\|') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)

# --- 1. Stories ------------------------------------------------------------------
Hdr "1 - Stories and acceptance criteria"
$storyOk = $false
if (Test-Path $stories) {
  $st = ReadText $stories
  $nStory = @([regex]::Matches($st, '(?m)^#+\s*US-\d+')).Count
  $nAc = @([regex]::Matches($st, '(?m)^\|\s*AC-\d+')).Count
  if ($nStory -ge 1) { Ok "$nStory $(if ($nStory -eq 1) { 'story' } else { 'stories' }) in stories.md" } else { Bad "stories.md has no story (## US-001 - ...)" }
  if ($st -match '(?im)^\*\*As\*\*|^As (a|an|the) ') { Ok "Stories are written As / I want / so that" } else { Warn "No 'As ... I want ... so that ...' found" }
  if ($st -match '(?i)As (a|an|the) user\b|\*\*As\*\* (a|an|the) user\b') { Warn "A story is for 'the user' - name the real role from spec section 2" }
  $nDeliv = @([regex]::Matches($st, '(?m)^Delivers:.*(FR|RULE|NFR)-\d{3}')).Count
  if ($nStory -ge 1 -and $nDeliv -ge $nStory) { Ok "Every story names the IDs it delivers" } else { Warn "$($nStory - $nDeliv) stor(ies) without a 'Delivers: FR-...' line" }
  if ($nAc -ge 1) {
    Ok "$nAc acceptance criteria"
    $noProof = @($st -split "\r?\n" | Where-Object { $_ -match '^\|\s*AC-\d+' -and $_ -notmatch '(FR|RULE|NFR)-\d{3}' }).Count
    if ($noProof -eq 0) { Ok "Every AC names what it proves" } else { Warn "$noProof AC row(s) do not name a requirement or rule row" }
    if ($nStory -ge 1 -and $nDeliv -ge 1) { $storyOk = $true }
  } else { Bad "No acceptance criteria (| AC-1 | Given | When | Then | Proves |)" }
  $unknown = @(Ids $st | Where-Object { $ids -notcontains $_ })
  if ($unknown.Count -eq 0) { Ok "Every ID in stories.md exists in spec.md" } else { Warn "IDs in stories.md that spec.md does not have: $($unknown -join ' ')" }
} else { Bad "No specs/$sliceName/stories.md - /spec-stories writes it (template: templates/stories.md)" }
if (Test-Path (Join-Path $sd "example-map.md")) { Ok "Example map kept (example-map.md)" } else { Warn "No example-map.md - the conversation behind the stories is not recorded" }

# --- 2. Spec first -----------------------------------------------------------------
Hdr "2 - The spec changed first"
$specFirst = $false
$specCommits = @(git -C $Repo log --format=%ct $range -- $specRel 2>$null)
if ($specCommits.Count -ge 1) {
  Ok "spec.md changed in layer 4 ($($specCommits.Count) commit(s))"
  $firstSpec = [long]($specCommits | Select-Object -Last 1)
  $featAdds = @(git -C $Repo log --format=%ct --diff-filter=A $range -- '*.feature' 2>$null)
  if ($featAdds.Count -eq 0 -or $firstSpec -le [long]($featAdds | Select-Object -Last 1)) { Ok "...before the first scenario was written" }
  else { Warn "The first .feature file came before the first spec change - was the spec changed afterwards to match?" }
  $specFirst = $true
} else { Warn "spec.md has not changed since L3-working - what did the example map change? (rule rows, answered and new questions)" }
if ($ruleRows.Count -ge 1) { Ok "$($ruleRows.Count) rule rows in the spec" } else { Warn "No rule rows (| RULE-001a | ... |) in spec.md section 5" }
$nq = @([regex]::Matches($specText, 'NEEDS CLARIFICATION')).Count
if ($nq -ge 1) { Ok "$nq open question(s) marked - not guessed" }

# --- 3. Scenarios ------------------------------------------------------------------
Hdr "3 - Executable scenarios, tagged with IDs"
$skip = '[\\/](node_modules|\.git|\.claude|target|templates)[\\/]'
$features = @(Get-ChildItem $Repo -Recurse -File -Filter *.feature -ErrorAction SilentlyContinue |
              Where-Object { ($_.FullName.Substring($Repo.Length) + '/') -notmatch $skip } | Sort-Object FullName)
$scenOk = $false; $coverOk = $false
if ($features.Count -ge 1) {
  $inSpec = @($features | Where-Object { $_.FullName.Substring($Repo.Length) -match '^[\\/]specs[\\/]' }).Count
  if ($inSpec -eq $features.Count) { Ok "$($features.Count) feature file(s), all next to the spec" } else { Warn "$($features.Count - $inSpec) feature file(s) outside specs/ - keep them with the spec they prove" }
  $scen = @(); $all = ""
  foreach ($f in $features) {
    $text = ReadText $f.FullName; $all += $text + "`n"
    $rel = $f.FullName.Substring($Repo.Length).TrimStart('\', '/') -replace '\\', '/'
    $pend = ""; $ftags = ""; $n = 0
    foreach ($l in ($text -split "\r?\n")) {
      $n++
      if ($l -match '^\s*@') { $pend += " " + $l; continue }
      if ($l -match '^\s*Feature:') { $ftags = $pend; $pend = ""; continue }
      if ($l -match '^\s*(Scenario|Scenario Outline|Scenario Template|Example):') { $scen += [pscustomobject]@{ Where = "${rel}:$n"; Tags = "$ftags $pend" }; $pend = ""; continue }
      if ($l -match '^\s*(Rule|Background|Examples|Scenarios):') { $pend = "" }
    }
  }
  Ok "$($scen.Count) scenario(s)"
  $untagged = @($scen | Where-Object { $_.Tags -notmatch '@(FR|NFR|RULE)-\d{3}' })
  if ($scen.Count -ge 1 -and $untagged.Count -eq 0) { Ok "Every scenario tagged with the ID it proves"; $scenOk = $true }
  elseif ($scen.Count -ge 1) { Bad "$($untagged.Count) scenario(s) with no @FR-/@RULE-/@NFR- tag:"; $untagged | Select-Object -First 5 | ForEach-Object { Write-Host "         $($_.Where)" } }
  $tagged = @([regex]::Matches($all, '@((FR|NFR|RULE)-\d{3}[a-z]?)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
  $badTag = @($tagged | Where-Object { $ids -notcontains $_ })
  if ($badTag.Count -eq 0) { Ok "Every tag is an ID in spec.md" } else { Warn "Tags with no such ID in spec.md: $($badTag -join ' ')" }
  $missingR = @($ruleRows | Where-Object { $all -notmatch "(^|[^A-Za-z0-9-])$_([^a-z0-9]|$)" -and $all -notmatch "@$($_.Substring(0, $_.Length - 1))([^a-z0-9]|$)" })
  if ($ruleRows.Count -ge 1 -and $missingR.Count -eq 0) { Ok "Every rule row has a scenario"; $coverOk = $true }
  elseif ($ruleRows.Count -ge 1) { Warn "Rule rows with no scenario: $($missingR -join ' ')" }
  $missingF = @($frs | Where-Object { $tagged -notcontains $_ })
  if ($missingF.Count -eq 0) { Ok "Every FR has a scenario" } else { Warn "FRs with no scenario yet: $($missingF -join ' ') - fine for now; list them in trace.md as 'none yet'" }
  if ($ruleRows.Count -eq 0 -and $scenOk) { $coverOk = $true }
  $imp = @($all -split "\r?\n" | Where-Object { $_ -match '(?i)^\s*(Given|When|Then|And|But)\b.*\b(click|clicks|button|page|field|types? |enters? |url|http|json|sql|select \* )' } | Select-Object -First 3)
  if ($imp.Count -eq 0) { Ok "Scenarios read as behaviour - no clicks, fields, URLs or SQL" }
  else { Warn "Imperative steps - say what happens, not how:"; $imp | ForEach-Object { Write-Host "         $($_.Trim())" } }
  if ($all -match 'Scenario (Outline|Template):') { Ok "Rule examples as a Scenario Outline" } else { Warn "No Scenario Outline - a rule with example rows is one outline, rows word for word from the spec" }
} else { Bad "No .feature files - /spec-scenarios writes them into specs/$sliceName/features/" }

# --- 4. Test first -----------------------------------------------------------------
Hdr "4 - Steps, and the rule built test-first"
$code = @(Get-ChildItem $Repo -Recurse -File -Include *.py, *.js, *.mjs, *.ts, *.java, *.cs, *.go -ErrorAction SilentlyContinue |
          Where-Object { ($_.FullName.Substring($Repo.Length) + '/') -notmatch '[\\/](node_modules|\.git|\.claude|target|templates)[\\/]' })
$steps = @($code | Where-Object { (ReadText $_.FullName) -match 'pytest_bdd|@cucumber/cucumber|io\.cucumber\.java|Reqnroll|godog' })
$stepsOk = $false
if ($steps.Count -ge 1) { Ok "$($steps.Count) step-definition file(s)"; $stepsOk = $true } else { Bad "No step definitions found (pytest-bdd, cucumber-js or Cucumber-JVM) - stacks/<stack>/README.md" }
$nIdTest = 0
foreach ($c in ($code | Where-Object { $_.Extension -in '.py', '.js', '.mjs', '.ts', '.java' })) {
  $nIdTest += @([regex]::Matches((ReadText $c.FullName), '(?i)(def test_|test\(|it\(|void )[^(]*(rule|fr|nfr)[_-]?\d{3}')).Count
}
if ($nIdTest -ge 1) { Ok "$nIdTest unit test(s) named after an ID" } else { Warn "No unit test named after a rule or requirement ID (test_rule_002b_...)" }
$subjects = @(git -C $Repo log --reverse --format=%s $range 2>$null)
$nTest = @($subjects | Where-Object { $_ -match '(?i)^test(\(.*\))?:' }).Count
$nFeat = @($subjects | Where-Object { $_ -match '(?i)^feat(\(.*\))?:' }).Count
$nRef = @($subjects | Where-Object { $_ -match '(?i)^refactor(\(.*\))?:' }).Count
$redFirst = $false; $seenTest = $false
foreach ($sbj in $subjects) { if ($sbj -match '(?i)^test(\(.*\))?:') { $seenTest = $true }; if ($seenTest -and $sbj -match '(?i)^feat(\(.*\))?:') { $redFirst = $true; break } }
$tddOk = $false
if ($redFirst) { Ok "Test-first trail in git: $nTest test:, $nFeat feat:, $nRef refactor: commit(s) - a test before the code"; $tddOk = $true }
elseif ($nTest -ge 1) { Warn "test: commits, but no feat: commit after one - commit each step: test: (red), feat: (green), refactor:" }
else { Warn "No test: / feat: commits since L3-working - commit each TDD step so the history shows it" }
$tddLog = Join-Path $sd "tdd-log.md"
if ((Test-Path $tddLog) -and ((ReadText $tddLog) -match '(?i)red')) { Ok "tdd-log.md records the cycles"; $tddOk = $true } else { Warn "No tdd-log.md in the slice - /tdd-cycle appends to it" }

# --- 5. Pipeline -------------------------------------------------------------------
Hdr "5 - The scenarios run in the pipeline"
$pipeOk = $false
if ((Test-Path $ci) -and ((ReadText $ci) -match '(?m)ci/scenarios\.yml|^scenarios:')) { Ok "Scenarios job in .gitlab-ci.yml"; $pipeOk = $true }
else { Warn "No scenarios job - setup-quality adds ci/scenarios.yml and includes it" }
$scy = Join-Path $Repo "ci\scenarios.yml"
if (Test-Path $scy) { if ((ReadText $scy) -match 'junit') { Ok "Scenario results reported to the merge request (junit)" } else { Warn "ci/scenarios.yml has no junit report" } }
git -C $Repo rev-parse -q --verify refs/tags/L4-behaviour 2>$null | Out-Null
$taggedL4 = ($LASTEXITCODE -eq 0)
$pushed = $false
git -C $Repo rev-parse --abbrev-ref '@{u}' 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $ahead = git -C $Repo rev-list --count '@{u}..HEAD' 2>$null; if ("$ahead".Trim() -eq '0') { $pushed = $true } }
if ($pushed) { Ok "Everything on this branch is pushed" } else { Warn "Not pushed" }

# --- 6. Quality gates ----------------------------------------------------------------
Hdr "6 - Quality gates - in the spec, and in the pipeline"
$qg = Join-Path $Repo "specs\design\quality-gates.md"; $qy = Join-Path $Repo "ci\quality.yml"
$qgOk = $false; $qpOk = $false
if (Test-Path $qg) {
  $qrows = @((ReadText $qg) -split "\r?\n" | Where-Object { $_ -match '^\|\s*QG-\d{3}' })
  if ($qrows.Count -ge 5) { Ok "specs/design/quality-gates.md - $($qrows.Count) gates" } else { Warn "quality-gates.md has $($qrows.Count) gate(s) - lint, complexity, secrets, SAST, dependencies at least" }
  $noRule = @($qrows | Where-Object { ($_ -split '\|')[3] -notmatch '(E|W|C|NFR|FR|RULE)-\d{3}|ADR|constraints|\b(FR|RULE)\b' }).Count
  if ($noRule -eq 0) { Ok "Every gate names the rule it enforces" } else { Warn "$noRule gate(s) do not name a rule - a gate with no rule is a habit, not a decision" }
  $cxRow = $qrows | Where-Object { $_ -match '^\|\s*QG-002' } | Select-Object -First 1
  $cxb = $null; if ($cxRow) { $cells = $cxRow -split '\|'; if ($cells[$cells.Count - 2] -match '(\d+)') { $cxb = $Matches[1] } }
  if ($cxb) { Ok "Complexity baseline recorded ($cxb)"; $qgOk = $true } else { Warn "No baseline in the QG-002 row - run quality-local, then /quality-gates" }
} else { Bad "No specs/design/quality-gates.md - run quality-local, then /quality-gates (template: templates/quality-gates.md)" }
$ciText = if (Test-Path $ci) { ReadText $ci } else { "" }
if (Test-Path $qy) {
  $qt = ReadText $qy
  $inc = $ciText -match 'ci/quality\.yml'
  if ($inc) { Ok "ci/quality.yml included in .gitlab-ci.yml" } else { Bad "ci/quality.yml is not included in .gitlab-ci.yml" }
  $missing = @('qa:lint', 'qa:complexity', 'qa:secrets', 'qa:sast', 'qa:dependencies') | Where-Object { $qt -notmatch "(?m)^$([regex]::Escape($_)):" }
  if (-not $missing) { Ok "Gates in the pipeline: lint, complexity, secrets, SAST, dependencies" } else { Warn "Missing from ci/quality.yml: $($missing -join ' ')" }
  if ($inc -and -not $missing) { $qpOk = $true }
  $off = @()
  foreach ($j in @('qa:secrets', 'qa:sast', 'qa:dependencies', 'qa:lint')) {
    $in = $false
    foreach ($l in ($qt -split "\r?\n")) {
      if ($l -eq "${j}:") { $in = $true; continue }
      if ($in -and $l -match '^\S') { $in = $false }
      if ($in -and $l -match 'allow_failure:\s*true') { $off += $j }
    }
  }
  if (-not $off) { Ok "No blocking gate switched off (allow_failure)" } else { Warn "Blocking gates set to allow_failure: $($off -join ' ') - is that in quality-gates.md, with a reason?" }
  $qcb = if ($qt -match '(?m)^\s+QA_COMPLEXITY_BASELINE:\s*"([^"]*)"') { $Matches[1] } else { "" }
  $qcl = if ($qt -match '(?m)^\s+QA_COMPLEXITY_LIMIT:\s*"([^"]*)"') { $Matches[1] } else { "" }
  if ($qcb) { Ok "Complexity ratchet on - baseline $qcb" } else { Warn "QA_COMPLEXITY_BASELINE is empty - complexity only reports. Set it from quality-gates.md" }
  if ((Test-Path $qg) -and $qcl -and $cxRow) {
    if ($cxRow -match "(^|[^0-9])$qcl([^0-9]|$)") { Ok "Spec and pipeline agree on the complexity limit ($qcl)" }
    else { Warn "QA_COMPLEXITY_LIMIT is $qcl, but the QG-002 row says otherwise - the spec decides; fix the pipeline" }
  }
} else { Bad "No ci/quality.yml - setup-quality adds the baseline quality pipeline" }
if ($ciText) {
  foreach ($j in @('lint', 'secrets')) { if ($ciText -match "(?m)^${j}:") { Warn "Session 10 job '${j}:' still in .gitlab-ci.yml - qa:$j replaces it; two jobs for one gate drift apart" } }
  $all = $ciText; Get-ChildItem (Join-Path $Repo "ci") -Filter *.yml -ErrorAction SilentlyContinue | ForEach-Object { $all += "`n" + (ReadText $_.FullName) }
  $latest = @($all -split "\r?\n" | Where-Object { $_ -match 'image:|name:' } | Where-Object { $_ -match ':latest' -or $_ -match 'image:\s*[a-z0-9./-]+\s*$' } | Select-Object -First 3)
  if (-not $latest) { Ok "Every pipeline image pinned to a version" }
  else { Warn "Images without a pinned version - a scanner on 'latest' runs whatever was published last:"; $latest | ForEach-Object { Write-Host "         $($_.Trim())" } }
}

Hdr "Ready for layer 5? (see BUILD-ROADMAP.md)"
$script:Miss = 0
function Bar($yes, $m) { if ($yes) { Write-Host "  [ HAVE ] $m" -ForegroundColor Green } else { Write-Host "  [ NEED ] $m" -ForegroundColor Red; $script:Miss++ } }
Bar $storyOk "Stories with acceptance criteria, each naming the IDs it proves"
Bar $specFirst "The spec changed first - rule rows and questions from the example map"
Bar $scenOk "Executable scenarios, every one tagged with its IDs"
Bar $coverOk "Every rule row has a scenario"
Bar $stepsOk "Thin step definitions that call the application"
Bar $tddOk "The rule built test-first - test: before feat:, or a tdd-log"
Bar $pipeOk "Scenarios run in the pipeline, with a report"
Bar $qgOk "Quality gates in the spec - each naming its rule, with today's baseline"
Bar $qpOk "The baseline quality pipeline - lint, complexity, secrets, SAST, dependencies"
Bar $taggedL4 "Tagged L4-behaviour"
Write-Host ""
if ($script:Miss -eq 0) { Write-Host "  READY - layer 4 is in. Layer 5 automates the confidence." -ForegroundColor Green }
else { Write-Host "  NOT YET - $($script:Miss) item(s) above." -ForegroundColor Yellow }

Write-Host ""
Write-Host "============================================================"
Write-Host " ok: $($script:Pass)   warnings: $($script:WarnN)   failed: $($script:Fail)"
Write-Host "============================================================"
if ($script:Fail -gt 0) { Write-Host " Something required is missing. Fix the [FAIL] lines and run again."; exit 1 }
if ($script:WarnN -gt 0) { Write-Host " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them." }
exit 0
