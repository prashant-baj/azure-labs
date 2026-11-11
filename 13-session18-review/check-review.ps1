# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-review.ps1  -  Session 18, layer 7: has the build been reviewed - and did the review change anything?
#                       A readiness checklist with evidence, a runbook someone else can use, the board's
#                       findings and the client's feedback decided, and the top findings fixed, test first.
#                       (Windows PowerShell 5.1 / PowerShell 7)
#
#  Checks files, records and git history. It does not judge the evidence - the board does that.
#
#  USAGE
#    ./check-review.ps1 [-Path "C:\work\group-1"]
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  Exit code is non-zero only if something required is missing.
#  A bash twin (check-review.sh) exists for macOS / Linux / WSL.
# =============================================================================
param([string]$Path = ".")

$script:Pass = 0; $script:WarnN = 0; $script:Fail = 0; $script:Miss = 0
function Ok($m)   { Write-Host "  [ OK ] $m" -ForegroundColor Green; $script:Pass++ }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow; $script:WarnN++ }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:Fail++ }
function Hdr($m)  { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function ReadText($p) { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }
function Lines($p) { if (Test-Path $p) { @((ReadText $p) -split "`r?`n") } else { @() } }

if (-not (Test-Path $Path)) { Write-Host "Path not found: $Path"; exit 1 }
$Repo = (Resolve-Path $Path).Path
$rd = Join-Path $Repo "specs/design/readiness.md"; $rb = Join-Path $Repo "ops/runbook.md"
$fd = Join-Path $Repo "specs/review/findings.md";  $fb = Join-Path $Repo "specs/review/feedback.md"
$testsIn = @('*test*', '*Test*', '*spec.*', 'tests/*', ':!*.claude/*', ':!*.md')

# Rows of the readiness checklist with a given prefix (PR, OR, CR)
function Rows($prefix) {
  @(Lines $rd | Where-Object { $_ -match "^\|\s*$prefix-\d{2}\s*\|" } | ForEach-Object {
    $c = $_ -split '\|'
    [pscustomobject]@{ Id = $c[1].Trim(); Ev = $c[4].Trim(); St = $c[5].Trim().ToLower(); Note = $c[6].Trim() }
  })
}
function MissingEvidence($prefix) {
  $out = @()
  foreach ($r in (Rows $prefix | Where-Object { $_.St -eq 'met' })) {
    foreach ($m in [regex]::Matches($r.Ev, '`[A-Za-z0-9_./-]+/[A-Za-z0-9_./-]+`')) {
      $p = $m.Value.Trim('`')
      if (-not (Test-Path (Join-Path $Repo $p))) { $out += $p }
    }
  }
  @($out | Sort-Object -Unique -CaseSensitive)
}

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Session 18 - layer 7 check"
Write-Host " $Repo"
Write-Host "============================================================"
if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository"; exit 1 }
git -C $Repo rev-parse -q --verify refs/tags/L6-production 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $base = "L6-production"; Ok "Layer 7 measured from tag L6-production" }
else { $base = ""; Warn "No tag L6-production - review what you have; what is missing is a finding" }

function Checklist($prefix, $label) {
  $rows = Rows $prefix
  $t = $rows.Count
  if ($t -eq 0) { Bad "No $label lines ($prefix-nn) in specs/design/readiness.md - setup-review adds them"; return $false }
  $f  = @($rows | Where-Object { $_.St -match '^(met|partly|gap|n\.a\.|n/a|na)$' }).Count
  $ne = @($rows | Where-Object { $_.St -eq 'met' -and $_.Ev -eq '' }).Count
  $nl = @($rows | Where-Object { ($_.St -eq 'partly' -or $_.St -eq 'gap') -and $_.Note -notmatch '(REV-[0-9]|FB-[0-9]|[Bb]acklog)' }).Count
  $nr = @($rows | Where-Object { ($_.St -eq 'n.a.' -or $_.St -eq 'n/a' -or $_.St -eq 'na') -and $_.Note -eq '' }).Count
  if ($f -eq $t) { Ok "$t $label lines, every one with a status" } else { Warn "$f of $t $label lines have a status (met, partly, gap, n.a.) - /readiness-check" }
  if ($ne -eq 0) { Ok "Every 'met' line names its evidence" } else { Warn "$ne 'met' line(s) with no evidence - no evidence, no met" }
  if ($nl -eq 0) { Ok "Every 'partly' or 'gap' line names its finding or backlog item" } else { Warn "$nl 'partly' or 'gap' line(s) without a REV-0nn or backlog item - an unowned gap" }
  if ($nr -ne 0) { Warn "$nr 'n.a.' line(s) without a reason" }
  $miss = MissingEvidence $prefix
  if ($miss.Count -eq 0) { Ok "Every path named as evidence is in the repo" } else { Warn "Evidence that is not in the repo: $($miss -join ' ')" }
  $met = @($rows | Where-Object { $_.St -eq 'met' }).Count
  $gap = @($rows | Where-Object { $_.St -eq 'gap' -or $_.St -eq 'partly' }).Count
  Write-Host "         $met met, $gap partly or gap"
  return ($f -eq $t -and $ne -eq 0 -and $nl -eq 0 -and $nr -eq 0 -and $miss.Count -eq 0)
}

# --- 1. Production readiness ------------------------------------------------------------------
Hdr "1 - Production readiness - every line with evidence, or an owned gap"
$prOk = $false
if (Test-Path $rd) { Ok "specs/design/readiness.md"; $prOk = (Checklist 'PR' 'production readiness') | Select-Object -Last 1 }
else { Bad "No specs/design/readiness.md - setup-review starts it, /readiness-check fills it" }

# --- 2. Operations readiness -------------------------------------------------------------------
Hdr "2 - Operations readiness - can someone else run it?"
$orOk = $false; $rbOk = $false
if (Test-Path $rd) {
  $orOk = (Checklist 'OR' 'operations readiness') | Select-Object -Last 1
  $cr = Rows 'CR'; $ct = $cr.Count; $cf = @($cr | Where-Object { $_.St -match '^(met|partly|gap|n\.a\.|n/a|na)$' }).Count
  if ($ct -ge 2 -and $cf -eq $ct) { Ok "Your case's $ct lines have a status" }
  elseif ($ct -ge 2) { Warn "$cf of $ct case lines (CR-nn) have a status"; $orOk = $false }
  else { Warn "No case lines (CR-01, CR-02) - copy yours from <lab>/templates/case-lines/"; $orOk = $false }
}
if (Test-Path $rb) {
  $rbt = ReadText $rb
  $left = [regex]::Matches($rbt, [regex]::Escape('(fill in)')).Count
  if ($left -eq 0) { Ok "ops/runbook.md - every section written"; $rbOk = $true }
  else { Warn "ops/runbook.md - $left _(fill in)_ left - /runbook drafts it from the repo" }
  if ($rbt -match 'rollback:test|(?i)roll back') { Ok "The runbook says how to roll back" } else { Warn "The runbook does not say how to roll back" }
  if ($rbt -match '(?i)rotate') { Ok "The runbook says how to rotate a secret" } else { Warn "The runbook does not say how to rotate a secret" }
} else { Warn "No ops/runbook.md - setup-review starts it, /runbook drafts it" }

# --- 3. The board's findings ---------------------------------------------------------------------
Hdr "3 - The board's findings - recorded and decided"
$fdOk = $false; $verdict = $false
$frows = @(Lines $fd | Where-Object { $_ -match '^\|\s*REV-\d+\s*\|' } | ForEach-Object {
  $c = $_ -split '\|'
  if ($c[4].Trim() -ne '') { [pscustomobject]@{ Sev = $c[2].Trim().ToLower(); Dec = $c[6].Trim().ToLower(); St = $c[7].Trim().ToLower(); Link = $c[8].Trim() } }
})
$nf = $frows.Count
if (-not (Test-Path $fd)) { Warn "No specs/review/findings.md - setup-review starts it" }
else {
  if ($nf -ge 3) { Ok "$nf findings from the board" } else { Warn "$nf finding(s) recorded - copy every finding from the board's scorecard (at least three)" }
  $nsev = @($frows | Where-Object { $_.Sev -notmatch '^(high|medium|low)$' }).Count
  $ndec = @($frows | Where-Object { $_.Dec -notmatch '^(fix now|spec change|backlog|accepted)' }).Count
  $nhigh = @($frows | Where-Object { $_.Sev -eq 'high' }).Count
  if ($nf -gt 0) { if ($nsev -eq 0) { Ok "Every finding has a severity ($nhigh high)" } else { Warn "$nsev finding(s) without a severity (high, medium, low)" } }
  if ($nf -gt 0) { if ($ndec -eq 0) { Ok "Every finding has a decision" } else { Warn "$ndec finding(s) without a decision (fix now, spec change, backlog, accepted) - /triage-review" } }
  $fdOk = ($nf -ge 3 -and $nsev -eq 0 -and $ndec -eq 0)
}
$vl = @(Lines $rd | Where-Object { $_ -match '^\*\*Verdict:\*\*' -and -not $_.Contains('(fill in)') })
if ((Test-Path $rd) -and $vl.Count -gt 0) { Ok "The board's verdict is recorded in the readiness checklist"; $verdict = $true }
else { Warn "The board's verdict is not in specs/design/readiness.md section 4 yet" }

# --- 4. Customer feedback ------------------------------------------------------------------------
Hdr "4 - Customer feedback - decided, not promised"
$fbOk = $false
$brows = @(Lines $fb | Where-Object { $_ -match '^\|\s*FB-\d+\s*\|' } | ForEach-Object {
  $c = $_ -split '\|'
  if ($c[3].Trim() -ne '') { [pscustomobject]@{ Who = $c[2].Trim(); Ty = $c[4].Trim().ToLower(); Dec = $c[5].Trim().ToLower() } }
})
$nb = $brows.Count
if (-not (Test-Path $fb)) { Warn "No specs/review/feedback.md - setup-review starts it" }
else {
  if ($nb -ge 1) { Ok "$nb piece(s) of feedback from the client's people" } else { Warn "No feedback recorded - write down what the client's people said in step 4, in their words" }
  $nty = @($brows | Where-Object { $_.Ty -notmatch '^(defect|spec change|new request|question)' }).Count
  $nbd = @($brows | Where-Object { $_.Dec -notmatch '^(fix now|spec change|backlog|declined)' }).Count
  $nwho = @($brows | Where-Object { $_.Who -eq '' }).Count
  if ($nb -gt 0) { if ($nty -eq 0) { Ok "Every piece has a type" } else { Warn "$nty piece(s) without a type (defect, spec change, new request, question)" } }
  if ($nb -gt 0) { if ($nbd -eq 0) { Ok "Every piece has a decision" } else { Warn "$nbd piece(s) without a decision (fix now, spec change, backlog, declined)" } }
  if ($nwho -ne 0) { Warn "$nwho piece(s) without who said it" }
  $fbOk = ($nb -ge 1 -and $nty -eq 0 -and $nbd -eq 0)
}

# --- 5. Remediation ------------------------------------------------------------------------------
Hdr "5 - The review changed something - the top findings fixed, test first"
$fixOk = $false
$ndone = @($frows | Where-Object { $_.St -eq 'done' }).Count
$ndnl = @($frows | Where-Object { $_.St -eq 'done' -and $_.Link -eq '' }).Count
if ($ndone -ge 1) { Ok "$ndone finding(s) done" } else { Warn "No finding is done yet - fix the top one or two today (step 6)" }
if ($ndnl -ne 0) { Warn "$ndnl done finding(s) without a link to the test, merge request or spec change" }
$ntr = @(git -C $Repo grep -hiE -e '(def |test\(|it\(|void |@DisplayName\(.)[^(]*(rev|fb)[_-]?[0-9]{2,3}' -- @testsIn 2>$null).Count
if ($ntr -ge 1) { Ok "$ntr test(s) named after a finding or feedback (test_rev_0nn_...)" } else { Warn "No test named after a finding (test_rev_0nn_...) - a fix starts with a test, seen red" }
$nsp = @(git -C $Repo grep -lE -e '(REV|FB)-[0-9]{2}' -- 'specs/*' ':!specs/review/*' ':!specs/design/readiness.md' 2>$null).Count
if ($nsp -ge 1) { Ok "$nsp spec, strategy or ADR file(s) changed for a finding" } else { Warn "No spec, strategy or ADR names a finding - the spec changes first" }
if ($base) { $ncm = @(git -C $Repo log --oneline -E "--grep=(REV|FB)-[0-9]{2}" "$base..HEAD" 2>$null).Count }
else { $ncm = @(git -C $Repo log --oneline -E "--grep=(REV|FB)-[0-9]{2}" 2>$null).Count }
if ($ncm -ge 1) { Ok "$ncm commit(s) name a finding" } else { Warn "No commit names a finding - fix: REV-0nn <what> - test first" }
$fixOk = ($ndone -ge 1 -and $ndnl -eq 0 -and $ntr -ge 1)
git -C $Repo rev-parse -q --verify refs/tags/L7-reviewed 2>$null | Out-Null
$tagged = ($LASTEXITCODE -eq 0)

Hdr "Ready for the integrated demo? (see BUILD-ROADMAP.md)"
function Bar($yes, $m) { if ($yes) { Write-Host "  [ HAVE ] $m" -ForegroundColor Green } else { Write-Host "  [ NEED ] $m" -ForegroundColor Red; $script:Miss++ } }
Bar $prOk "Production readiness - every line with evidence, or an owned gap"
Bar $orOk "Operations readiness - every line, and your case's two"
Bar $rbOk "A runbook someone outside the group can use"
Bar ($fdOk -and $verdict) "The board's findings recorded and decided, and its verdict"
Bar $fbOk "The client's feedback triaged - no promises"
Bar $fixOk "The top findings fixed, each with a test named after it"
Bar $tagged "Tagged L7-reviewed"
Write-Host ""
if ($script:Miss -eq 0) { Write-Host "  READY - layer 7 is in. Reviewed by a board - and here is what you fixed." -ForegroundColor Green }
else { Write-Host "  NOT YET - $($script:Miss) item(s) above." -ForegroundColor Yellow }

Write-Host ""
Write-Host "============================================================"
Write-Host " ok: $($script:Pass)   warnings: $($script:WarnN)   failed: $($script:Fail)"
Write-Host "============================================================"
if ($script:Fail -gt 0) { Write-Host " Something required is missing. Fix the [FAIL] lines and run again."; exit 1 }
if ($script:WarnN -gt 0) { Write-Host " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them." }
exit 0
