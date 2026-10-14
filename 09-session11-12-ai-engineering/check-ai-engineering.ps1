# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-ai-engineering.ps1  -  Sessions 11 and 12, layer 3: does the slice work,
#                               built through merge requests, validated, with the
#                               spec strengthened?
#                               (Windows PowerShell 5.1 / PowerShell 7)
#
#  Checks structure, records and git discipline - never whether the code is good.
#  That is what the review threads, the validation and the debrief are for.
#
#  USAGE
#    ./check-ai-engineering.ps1 -Path "C:\work\group-1" [-Slice "specs\001-first-slice"]
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  Exit code is non-zero only if something required is missing - or a secret is committed.
#  A bash twin (check-ai-engineering.sh) exists for macOS / Linux / WSL.
# =============================================================================
param(
  [string]$Path = ".",
  [string]$Slice = ""
)
$script:Pass = 0; $script:WarnN = 0; $script:Fail = 0
function Ok($m)   { Write-Host "  [ OK ] $m" -ForegroundColor Green;  $script:Pass++ }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow; $script:WarnN++ }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red;    $script:Fail++ }
function Hdr($m)  { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function Lines($p) { if ($p -and (Test-Path $p)) { [System.IO.File]::ReadAllLines($p, [System.Text.Encoding]::UTF8) } else { @() } }
function Cell($row, $n) { $c = $row.Split('|'); if ($c.Count -gt $n) { $c[$n].Trim() } else { "" } }

if (-not (Test-Path $Path)) { Write-Host "Path not found: $Path"; exit 1 }
$Repo = (Resolve-Path $Path).Path
$specsDir = Join-Path $Repo "specs"
if ($Slice) {
  $SliceDir = Join-Path $Repo $Slice
  if (-not (Test-Path $SliceDir)) { $SliceDir = Join-Path $specsDir $Slice }
} else {
  $last = Get-ChildItem $specsDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d{3}-' } | Sort-Object Name | Select-Object -Last 1
  $SliceDir = $null; if ($last) { $SliceDir = $last.FullName }
}

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Sessions 11-12 - layer 3 check"
Write-Host " $Repo"
Write-Host "============================================================"

if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository"; exit 1 }
$SpecP = $null; if ($SliceDir) { $SpecP = Join-Path $SliceDir "spec.md" }
if (-not $SpecP -or -not (Test-Path $SpecP)) { Bad "No slice spec found (specs/NNN-name/spec.md)"; exit 1 }
$sliceName = Split-Path $SliceDir -Leaf
Ok "Slice: specs/$sliceName"
git -C $Repo rev-parse -q --verify refs/tags/L2-design 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $Range = "L2-design..HEAD"; Ok "Layer 3 measured from tag L2-design" }
else { $Range = "HEAD"; Warn "No tag L2-design - measuring the whole history instead" }
$ciP = Join-Path $Repo ".gitlab-ci.yml"
$ciT = ""; if (Test-Path $ciP) { $ciT = (Lines $ciP) -join "`n" }

# --- 1. The pipeline -----------------------------------------------------------------
Hdr "1 - The pipeline"
if (-not (Test-Path $ciP)) { Bad "No .gitlab-ci.yml - run setup-ai-engineering" }
else {
  Ok ".gitlab-ci.yml present"
  if ($ciT -match '(?m)ci/ai-review\.yml|^ai-review:') { Ok "AI review runs on every merge request" } else { Warn "AI review not included - add:  include: [{ local: ci/ai-review.yml }]" }
  if ($ciT -match 'reports:|junit') { Ok "Test results reported to the merge request (junit)" } else { Warn "No test job with a junit report yet - 08-session10-excellence/ci/ has starters" }
  if ($ciT -match '(?m)^spec-present:') { Warn "The placeholder job spec-present is still there - replace it with your real test job" }
}
if (Test-Path (Join-Path $Repo "ci\post-review.mjs")) { Ok "ci/post-review.mjs present" } else { Warn "ci/post-review.mjs missing - the review cannot post its threads" }
$leakRx = 'sk-ant-[A-Za-z0-9_-]{20,}|glpat-[A-Za-z0-9_-]{20,}|CLAUDE_CODE_OAUTH_TOKEN[[:space:]]*[:=][[:space:]]*["'']?[A-Za-z0-9_-]{20,}|ANTHROPIC_API_KEY[[:space:]]*[:=][[:space:]]*["'']?[A-Za-z0-9_-]{20,}'
$leak = @(git -C $Repo grep -nIE $leakRx 2>$null | Select-Object -First 3)
if ($leak.Count -eq 0) { Ok "No tokens or keys committed" }
else { Bad "A token or key is committed - revoke it now, then remove it (W-004):"; $leak | ForEach-Object { $p = $_.Split(':'); Write-Host ("           " + $p[0] + ":" + $p[1] + "  (value hidden)") } }

# --- Azure (Session 11): gaps found, infrastructure as code, no state in git ---------------
Hdr "1b - Azure - gaps and infrastructure as code"
if (Test-Path (Join-Path $Repo "specs\design\azure-gaps.md")) { Ok "specs/design/azure-gaps.md - gaps found and asked about" } else { Warn "No specs/design/azure-gaps.md - run /azure-gaps before writing Terraform" }
if (@(Get-ChildItem (Join-Path $Repo "infra") -Filter *.tf -ErrorAction SilentlyContinue).Count -gt 0) { Ok "infra/ has Terraform" } else { Warn "No infra/*.tf yet - /azure-terraform writes it (Session 12 deploy exercise)" }
$depLog = Join-Path $Repo "infra\deployments.md"; $ndep = 0
if (Test-Path $depLog) { $ndep = @(Get-Content $depLog | Where-Object { $_ -match '^\|\s*[0-9]+\s*\|' }).Count }
if ($ndep -ge 1) { Ok "infra/deployments.md - $ndep deployment(s) logged" } else { Warn "No deployment logged in infra/deployments.md - see DEPLOY-EXERCISE.md, checkpoint 6" }
$state = @(git -C $Repo ls-files 2>$null | Where-Object { $_ -match '(^|/)([^/]*\.tfstate(\.backup)?|\.terraform/.*|[^/]*\.tfvars)$' -and $_ -notmatch '\.tfvars\.example$' } | Select-Object -First 3)
if ($state.Count -eq 0) { Ok "No Terraform state, .terraform/ or .tfvars committed" }
else { Bad "Terraform state or variables are committed - they can hold secrets. Remove them and add to .gitignore:"; $state | ForEach-Object { Write-Host "           $_" } }

# --- 2. Building through merge requests -------------------------------------------------
Hdr "2 - The slice, built through merge requests"
$nmerge = @(git -C $Repo log --merges --oneline $Range 2>$null | Where-Object { $_ }).Count
if ($nmerge -ge 3) { Ok "$nmerge merge(s) in layer 3 - work arrived task by task" } else { Warn "$nmerge merge(s) in layer 3 - one merge request per task, or a few tasks each" }
$cc = @(git -C $Repo log --no-merges --format='%s' $Range -- '*.py' '*.java' '*.kt' '*.js' '*.ts' '*.cs' '*.go' ':!specs/**' ':!docs/**' ':!templates/**' ':!examples/**' ':!.claude/**' ':!ci/**' 2>$null | Where-Object { $_ })
$not = @($cc | Where-Object { $_ -notmatch 'T\d{3}|refactor:|fix:|finding' }).Count
if ($cc.Count -eq 0) { Warn "No code commits in layer 3 yet" }
elseif ($not -eq 0) { Ok "All $($cc.Count) code commit(s) name a task, a fix or a finding" }
else { Warn "$not of $($cc.Count) code commit(s) name no task - 'T009: ... (FR-001)'" }
$T = Lines (Join-Path $SliceDir "tasks.md")
if ($T.Count -gt 0) {
  $tot = @($T | Where-Object { $_ -match '^- \[[ xX]\] T\d{3}' }).Count
  $done = @($T | Where-Object { $_ -match '^- \[[xX]\] T\d{3}' }).Count
  if ($tot -gt 0) { Ok "tasks.md: $done of $tot task(s) ticked" } else { Warn "No tasks in tasks.md" }
  if ($tot -gt 0 -and $done -eq 0) { Warn "No task ticked yet - tick a task in the same merge request that finishes it" }
}
$n = @(git -C $Repo log --oneline $Range -- README.md 2>$null | Where-Object { $_ }).Count
if ($n -gt 0) { Ok "README.md changed in layer 3 - docs move with the code" } else { Warn "README.md not changed in layer 3 - does it still say how to run the slice?" }
$n = @(git -C $Repo log --oneline $Range -- "specs/$sliceName/trace.md" 2>$null | Where-Object { $_ }).Count
if ($n -gt 0) { Ok "trace.md changed in layer 3" } else { Warn "trace.md not changed in layer 3 - re-run /spec-trace: which requirements now have code and tests?" }

# --- 3. The spec, strengthened with AI ----------------------------------------------
Hdr "3 - The spec, strengthened with AI (Session 12)"
$srev = Join-Path $SliceDir "reviews\spec-review.md"; $sundec = 1
if (-not (Test-Path $srev)) { Warn "No specs/$sliceName/reviews/spec-review.md - run /spec-review (Session 12)" }
else {
  $srows = @((Lines $srev) | Where-Object { $_ -match '^\|\s*\d+\s*\|' })
  Ok "Spec review: $($srows.Count) finding(s)"
  $kinds = @($srows | ForEach-Object { [regex]::Matches((Cell $_ 2).ToLower(), 'ambiguous|untestable|missing if|missing example|conflict|no source|glossary|not asked') | ForEach-Object { $_.Value } } | Sort-Object -Unique).Count
  if ($kinds -ge 3) { Ok "$kinds kinds of weakness looked for" } else { Warn "Only $kinds kind(s) of finding - look again: ambiguity, testability, missing If rows, conflicts" }
  $sundec = @($srows | Where-Object { (Cell $_ 6) -eq "" }).Count
  if ($srows.Count -gt 0) { if ($sundec -eq 0) { Ok "Every spec finding decided by the group" } else { Warn "$sundec spec finding(s) not decided - change, keep with a reason, or ask the client" } }
  else { $sundec = 0 }
}
git -C $Repo rev-parse -q --verify refs/tags/L2-design *> $null
if ($LASTEXITCODE -eq 0) {
  $specRel = $SpecP.Substring($Repo.Length + 1) -replace '\\','/'
  $nspec = @(git -C $Repo log --oneline L2-design..HEAD -- $specRel 2>$null).Count
  if ($nspec -ge 1) { Ok "spec.md changed in layer 3 ($nspec commit(s))" } else { Warn "spec.md unchanged since L2-design - did the review change nothing?" }
}
$nif = @((Lines $SpecP) | Where-Object { $_ -match '^\|\s*FR-\d{3}\s*\|\s*If ' }).Count
if ($nif -ge 2) { Ok "$nif 'If ... then' requirements in the spec" } else { Warn "$nif 'If' requirement(s) - /spec-review looks for the failure paths you have not written" }
$ncl = @((Lines $SpecP) | Where-Object { $_ -match 'NEEDS CLARIFICATION' }).Count
if ($ncl -eq 0) { Ok "No open NEEDS CLARIFICATION in the spec" } else { Warn "$ncl NEEDS CLARIFICATION still open - who in the client's team will answer them?" }

# --- 4. Validation ------------------------------------------------------------------------
Hdr "4 - Validation - four lenses, decided by people"
$val = Get-ChildItem (Join-Path $SliceDir "reviews") -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '(?i)L3|validation' -and $_.Name -notmatch 'spec-review' } | Sort-Object Name | Select-Object -Last 1
$undec = 1
if (-not $val) { Warn "No validation in specs/$sliceName/reviews/ - run /validate-ai-code (Session 12)" }
else {
  $V = Lines $val.FullName
  $rows = @($V | Where-Object { $_ -match '^\|\s*\d+\s*\|' })
  Ok ("Validation: specs/$sliceName/reviews/" + $val.Name + " - $($rows.Count) finding(s)")
  $lenses = @($rows | ForEach-Object { [regex]::Matches((Cell $_ 2).ToLower(), 'correctness|security|maintainability|compliance') | ForEach-Object { $_.Value } } | Sort-Object -Unique).Count
  if ($lenses -ge 3) { Ok "$lenses of the four lenses used" } else { Warn "Only $lenses lens(es) used - look again through the others" }
  $undec = @($rows | Where-Object { (Cell $_ 8) -eq "" }).Count
  if ($rows.Count -gt 0) { if ($undec -eq 0) { Ok "Every finding decided by the group" } else { Warn "$undec finding(s) not decided - fix, debt, or overruled with a reason" } }
  else { $undec = 0 }
  if (($V -join "`n") -match '(?i)Tests\s*\|[^|]*\|\s*[A-Za-z0-9]') { Ok "Real tool results quoted" } else { Warn "The 'What the tools said' table is empty - run the tools, quote them" }
}

# --- 5. Tag and push ------------------------------------------------------------------------
Hdr "5 - The tag"
git -C $Repo rev-parse -q --verify refs/tags/L3-working 2>$null | Out-Null
$tagged = ($LASTEXITCODE -eq 0)
if ($tagged) { Ok "Tag L3-working" } else { Warn "No tag L3-working yet - tag main at the end of Session 12" }
$pushed = $false
git -C $Repo rev-parse --abbrev-ref '@{u}' 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $pushed = ([int](git -C $Repo rev-list --count '@{u}..HEAD' 2>$null) -eq 0) }
if ($pushed) { Ok "Everything on this branch is pushed" } else { Warn "Not pushed" }

Hdr "Ready for layer 4? (see BUILD-ROADMAP.md)"
$script:Miss = 0
function Bar($have, $m) { if ($have) { Write-Host "  [ HAVE ] $m" -ForegroundColor Green } else { Write-Host "  [ NEED ] $m" -ForegroundColor Red; $script:Miss++ } }
Bar ($ciT -match '(?m)ci/ai-review\.yml|^ai-review:') "AI review in the pipeline"
Bar ($nmerge -ge 1) "Work merged through merge requests"
Bar ((Test-Path $srev) -and $sundec -eq 0) "Spec reviewed with AI, every finding decided by the group"
Bar ($val -and $undec -eq 0) "Validation through the four lenses, every finding decided"
Bar ($ndep -ge 1) "Deployed to Azure with Terraform, logged in infra/deployments.md"
Bar ($leak.Count -eq 0) "No tokens or keys in the repository"
Bar $tagged "Tagged L3-working"
Write-Host ""
if ($script:Miss -eq 0) { Write-Host "  READY - layer 3 is in. Layer 4 proves the behaviour." -ForegroundColor Green }
else { Write-Host "  NOT YET - $($script:Miss) item(s) above." -ForegroundColor Yellow }

Write-Host ""
Write-Host "============================================================"
Write-Host (" ok: {0}   warnings: {1}   failed: {2}" -f $script:Pass, $script:WarnN, $script:Fail)
Write-Host "============================================================"
if ($script:Fail -gt 0) { Write-Host " Something required is missing. Fix the [FAIL] lines and run again."; exit 1 }
if ($script:WarnN -gt 0) { Write-Host " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them." }
exit 0
