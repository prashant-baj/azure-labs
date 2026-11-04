# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-production.ps1  -  Sessions 16 and 17, layer 6: is it secure, observable and ready for production?
#                           A threat model with tested controls, secrets from the environment, a scan of
#                           the running service, one business and one technical signal in Application
#                           Insights, alerts, a drill and a rollback. (Windows PowerShell 5.1 / PowerShell 7)
#
#  Checks files, records and git history. It does not deploy or query Azure - the pipeline does that,
#  and confidence.md (dast.*, obs.* rows) in each pipeline is the evidence.
#
#  USAGE
#    ./check-production.ps1 [-Path "C:\work\group-1"]
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  Sections 1-4 are Session 16, sections 5-8 Session 17.
#  Exit code is non-zero only if something required is missing.
#  A bash twin (check-production.sh) exists for macOS / Linux / WSL.
# =============================================================================
param([string]$Path = ".")

$script:Pass = 0; $script:WarnN = 0; $script:Fail = 0; $script:Miss = 0
function Ok($m)   { Write-Host "  [ OK ] $m" -ForegroundColor Green; $script:Pass++ }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow; $script:WarnN++ }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:Fail++ }
function Hdr($m)  { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function ReadText($p) { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }
function Lines($p) { if (Test-Path $p) { @((ReadText $p) -split "`r?`n") } else { @() } }
function Flat($p) { if (Test-Path $p) { (ReadText $p) -replace "`r?`n", ' ' } else { "" } }
# Lines from the first line matching $start up to the next line starting "## " (both included)
function Section($lines, $start) {
  $out = @(); $on = $false
  foreach ($l in $lines) {
    if (-not $on) { if ($l -match $start) { $on = $true; $out += $l } }
    else { $out += $l; if ($l -match '^## ') { break } }
  }
  ,$out
}
# Lines from the first line matching $start to the end of the file
function FromLine($lines, $start) { $out = @(); $on = $false; foreach ($l in $lines) { if (-not $on -and $l -match $start) { $on = $true }; if ($on) { $out += $l } }; ,$out }

if (-not (Test-Path $Path)) { Write-Host "Path not found: $Path"; exit 1 }
$Repo = (Resolve-Path $Path).Path
$ci  = Join-Path $Repo ".gitlab-ci.yml"
$py  = Join-Path $Repo "ci/production.yml"
$st  = Join-Path $Repo "specs/design/test-strategy.md"
$tm  = Join-Path $Repo "specs/design/threat-model.md"
$os  = Join-Path $Repo "specs/design/observability.md"
$inf = Join-Path $Repo "infra"
$pyText = if (Test-Path $py) { ReadText $py } else { "" }
function PVar($name) { $m = [regex]::Match($pyText, "(?m)^[ \t]+${name}:[ \t]*`"([^`"]*)`""); if ($m.Success) { $m.Groups[1].Value } else { "" } }
$codeEx  = @('.', ':!*.claude/*', ':!specs/*', ':!templates/*', ':!ci/*', ':!infra/*', ':!*.md', ':!.gitlab-ci.yml', ':!*test*', ':!*Test*')
$testsIn = @('*test*', '*Test*', '*spec.*', 'tests/*', ':!*.claude/*', ':!*.md')
# your code: everything tracked except specs, templates, pipeline, Terraform, docs, tests and Claude's files
function CodeHas($flags, $pat) { git -C $Repo grep $flags -e $pat -- @codeEx 2>$null | Out-Null; $LASTEXITCODE -eq 0 }
function TestsHas($flags, $pat) { git -C $Repo grep $flags -e $pat -- @testsIn 2>$null | Out-Null; $LASTEXITCODE -eq 0 }
function TestsCount($pat) { @(git -C $Repo grep -hiE -e $pat -- @testsIn 2>$null).Count }
$rows = @(Lines $st | Where-Object { $_ -match '^\|\s*CS-\d{3}\s*\|.*\|\s*(merge|deploy)\s*\|\s*$' })
function RowHas($re) { @($rows | Where-Object { $_ -match $re }).Count -gt 0 }

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Sessions 16-17 - layer 6 check"
Write-Host " $Repo"
Write-Host "============================================================"
if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository"; exit 1 }
git -C $Repo rev-parse -q --verify refs/tags/L5-tested 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Ok "Layer 6 measured from tag L5-tested" } else { Warn "No tag L5-tested - layer 5 first, or tag what you have" }

# --- 1. Threat model ------------------------------------------------------------------------
Hdr "1 - The threat model - every threat a control and a test"
$threatOk = $false
if (Test-Path $tm) {
  Ok "specs/design/threat-model.md"
  $trows = @(Lines $tm | Where-Object { $_ -match '^\|\s*T-\d{2}\s*\|' } | Where-Object { (($_ -split '\|')[3]).Trim() -ne '' })
  $nt = $trows.Count
  $stride = 0
  foreach ($w in @('Spoof', 'Tamper', 'Repudiat', 'Information', 'Denial', 'Elevation')) { if (@($trows | Where-Object { ($_ -split '\|')[2] -match $w }).Count -gt 0) { $stride++ } }
  $noctl = @($trows | Where-Object { (($_ -split '\|')[4]).Trim() -eq '' }).Count
  $unproved = ""
  foreach ($r in $trows) {
    $c = $r -split '\|'; $id = $c[1].Trim(); $n = $id.Substring(2)
    if ($c[5] -match 'verify:|qa:') { continue }
    if (TestsHas '-qiE' "(^|[^a-z0-9])t[_-]?$n([^0-9]|`$)") { continue }
    $unproved += " $id"
  }
  if ($nt -ge 4) { Ok "$nt threats, across $stride of the six STRIDE letters" } else { Warn "$nt threat(s) written - STRIDE letter by letter, what could an outsider, a user out of role, an insider do? (/threat-model)" }
  if ($nt -gt 0) { if ($noctl -eq 0) { Ok "Every threat names its control" } else { Warn "$noctl threat(s) with no control - SEC-0nn, or move it to 'Accepted for now'" } }
  if ($nt -gt 0 -and -not $unproved) { Ok "Every threat is proved - a test named after it, or a pipeline job" }
  elseif ($nt -gt 0) { Warn "No test named after:$unproved - test_sec_0nn_t0n_..., red first" }
  $acc = @((Section (Lines $tm) '[Aa]ccepted for now') | Where-Object { $_ -match '^\|\s*[A-Za-z]' -and $_ -notmatch '^\|\s*Threat\s*\|' }).Count
  if ($acc -ge 1) { Ok "$acc risk(s) accepted for now, written down" } else { Warn "Nothing under 'Accepted for now' - is every threat really fixed in this slice?" }
  $threatOk = ($nt -ge 4 -and $noctl -eq 0 -and -not $unproved)
} else { Bad "No specs/design/threat-model.md - /threat-model writes it (setup-production starts it)" }
$tn = Join-Path $Repo "specs/design/threat-notes.md"
if (Test-Path $tn) {
  $tl = Lines $tn
  $done = @($tl | Where-Object { $_ -match '^- \[x\]' }).Count; $open = @($tl | Where-Object { $_ -cmatch '^- \[ \]' }).Count
  if ($open -eq 0 -and $done -gt 0) { Ok "Case notes: all $done checks ticked (specs/design/threat-notes.md)" }
  else { Warn "Case notes: $done of $($done + $open) checks ticked - specs/design/threat-notes.md, 'Before you finish step 2'" }
} else { Warn "No specs/design/threat-notes.md - your case's checks: copy <lab>/case-notes/case-<letter>-*.md there" }

# --- 2. Controls ------------------------------------------------------------------------------
Hdr "2 - The controls - in the code, tested, named after their threats"
$nsec = TestsCount '(def |test\(|it\(|void |@DisplayName\(.)[^(]*sec[_-]?[0-9]{3}'
if ($nsec -ge 3) { Ok "$nsec security tests named after their control (test_sec_001_...)" } else { Warn "$nsec security test(s) named SEC-0nn - one per control, red first (stacks.md, section 1)" }
if (CodeHas '-qiE' 'X-Content-Type-Options|helmet\(') { Ok "Security headers set in the code (SEC-002)" } else { Warn "No security headers in the code - stacks.md, section 2" }
if (CodeHas '-qiE' 'compare_digest|timingSafeEqual|MessageDigest\.isEqual') { Ok "Secrets compared in constant time" } else { Warn "No constant-time comparison found - hmac.compare_digest / timingSafeEqual / MessageDigest.isEqual" }
if (CodeHas '-qiE' 'x-api-key|api_key|apikey') { Ok "Protected routes ask for a key, not only a role header (T-01)" } else { Warn "No API key check found in the code - does a role header alone still get in?" }
$secOk = ($nsec -ge 3)

# --- 3. Secrets -------------------------------------------------------------------------------
Hdr "3 - Secrets - from the environment, never in git"
$secretsOk = $true
$tracked = @(git -C $Repo ls-files 2>$null | Where-Object { $_ -match '(\.tfvars|\.tfstate|\.tfstate\.backup|(^|/)\.env|\.pem|\.key|fed-cred\.json)$' })
if ($tracked.Count -gt 0) { Bad "In git, and must not be: $($tracked -join ' ') - git rm --cached, rotate the secret, add to .gitignore"; $secretsOk = $false }
else { Ok "No .tfvars, state, .env, keys or credentials files in git" }
$sec = Join-Path $inf "secrets.tf"
if (Test-Path $sec) {
  $sf = Flat $sec
  if ($sf -match 'sensitive\s*=\s*true') { Ok "infra/secrets.tf - the secret variables are sensitive" } else { Warn "infra/secrets.tf has no sensitive = true - plan output would show the value"; $secretsOk = $false }
  if ($sf -match 'default\s*=\s*"[^"]+"') { Bad "infra/secrets.tf has a default value - a secret's value never goes in a file"; $secretsOk = $false }
} else { Warn "No infra/secrets.tf - setup-production adds it"; $secretsOk = $false }
$main = Join-Path $inf "main.tf"
if ((Test-Path $main) -and (ReadText $main).Contains('app_secret_names')) { Ok "main.tf hands each secret to the Container App as a secret, not a plain setting" }
else { Warn "main.tf does not use local.app_secret_names - paste the snippet (WORKSHOP-S16.md, step 4)"; $secretsOk = $false }
$ntf = @(Lines $py | Where-Object { $_ -cmatch '^\s+TF_VAR_[a-z0-9_]+:\s*"\$[A-Z0-9_]+"' }).Count
if ($ntf -ge 1) { Ok "$ntf GitLab variable(s) handed to Terraform in ci/production.yml - secrets stay masked" } else { Warn "No TF_VAR_<name>: `"`$VARIABLE`" line in ci/production.yml - how does the secret reach Terraform?"; $secretsOk = $false }
$leak = 0
foreach ($e in @(Get-ChildItem (Join-Path $Repo "tests/api") -Filter "*environment*.json" -File -ErrorAction SilentlyContinue)) {
  if ((Flat $e.FullName) -match '"key"\s*:\s*"[^"]*(key|token|secret|password)[^"]*"\s*,\s*"value"\s*:\s*"[^"]+"') { $leak++ }
}
if ($leak -eq 0) { Ok "Postman environments hold no key, token or password values" } else { Bad "$leak Postman environment(s) hold a key or token value - empty it; the pipeline passes it with --env-var"; $secretsOk = $false }

# --- 4. DAST -----------------------------------------------------------------------------------
Hdr "4 - The scan of the running service"
$dastOk = $false; $inc = $false; $hasDast = $pyText -match '(?m)^verify:dast:'
if (Test-Path $py) {
  Ok "ci/production.yml"
  if ((Test-Path $ci) -and (ReadText $ci).Contains('ci/production.yml')) { Ok "Included from .gitlab-ci.yml"; $inc = $true } else { Bad "ci/production.yml is not included from .gitlab-ci.yml" }
  if ($hasDast) { Ok "verify:dast scans the deployed service after every deploy" } else { Warn "No verify:dast job" }
} else { Bad "No ci/production.yml - setup-production adds it" }
if (RowHas 'dast\.high') { Ok "The strategy has a dast.high row" } else { Warn "No dast.high row in the strategy - the scan decides nothing" }
$dh = @($rows | Where-Object { $_ -match 'dast\.high' })
if ($dh.Count -gt 0) { if (($dh[0] -split '\|')[4] -match '^\s*=\s*0\s*$') { Ok "dast.high = 0 - no high-risk finding is allowed" } else { Warn "dast.high is not '= 0' - which high-risk finding would you deploy with?" } }
if (RowHas 'dast\.medium') { Ok "dast.medium row - a ratchet from the first scan" } else { Warn "No dast.medium row - set it from the first scan's count, then it only goes down" }
$dastOk = ($inc -and $hasDast -and (RowHas 'dast\.high'))

# --- 5. Observability spec ----------------------------------------------------------------------
Hdr "5 - The observability spec - one business signal, one technical signal"
$obsSpecOk = $false; $metric = PVar 'OBS_BUSINESS_METRIC'; $biz = $false; $tecNfr = $false
if (Test-Path $os) {
  Ok "specs/design/observability.md"
  $ol = Lines $os
  $biz = @($ol | Where-Object { $_ -match '^\|\s*OBS-001\s*\|' -and $_ -match 'business' } | Where-Object { $s = (($_ -split '\|')[3]) -replace '[\s`]', ''; $s -ne '' -and $s -notmatch '^<name>' }).Count -gt 0
  $tec = @($ol | Where-Object { $_ -match '^\|\s*OBS-002\s*\|' -and $_ -match 'technical' })
  $tecNfr = @($tec | Where-Object { $_ -match 'NFR-\d{3}' }).Count -gt 0
  if ($biz) { Ok "OBS-001 is a business signal" } else { Warn "No business signal in OBS-001 - what number would the client phone you about? (/observability-spec)" }
  if ($tecNfr -and -not (@($tec | Where-Object { $_.Contains('NFR-0nn') }).Count -gt 0)) { Ok "OBS-002 is a technical signal that quotes an NFR" }
  else { Warn "OBS-002 does not quote an NFR row - p95 against which number the client agreed?" }
  if ($metric -and (ReadText $os).Contains($metric)) { Ok "The spec names the metric the pipeline checks: $metric" }
  else { $shown = if ($metric) { $metric } else { 'unset' }; Warn "OBS_BUSINESS_METRIC in ci/production.yml ($shown) is not named in the spec" }
  $obsSpecOk = ($biz -and $tecNfr)
} else { Warn "No specs/design/observability.md - Session 17: /observability-spec writes it" }

# --- 6. Instrumentation ------------------------------------------------------------------------
Hdr "6 - The code is instrumented - telemetry, the business metric, X-Request-Id"
$tel = CodeHas '-qE' 'configure_azure_monitor|useAzureMonitor|applicationinsights-agent'
if ($tel) { Ok "Telemetry to Application Insights (the distro or the agent), on only when configured" } else { Warn "No Application Insights instrumentation - stacks.md, section 5" }
$met = $false
if ($metric -and (CodeHas '-qF' $metric)) { Ok "The code creates the business metric $metric"; $met = $true }
else { $shown = if ($metric) { $metric } else { 'the business metric' }; Warn "The code does not create $shown - a counter, in the use case (stacks.md, section 6)" }
$rid = CodeHas '-qi' 'X-Request-Id'
if ($rid) { Ok "Every response carries X-Request-Id" } else { Warn "No X-Request-Id - stacks.md, section 7" }
if (CodeHas '-q' 'DRILL_SLOW_MS') { Ok "The drill switch is in the code" } else { Warn "No drill switch (DRILL_SLOW_MS, DRILL_ERROR_PCT) - stacks.md, section 8" }
$nobs = TestsCount '(def |test\(|it\(|void |@DisplayName\(.)[^(]*obs[_-]?[0-9]{3}'
if ($nobs -ge 1) { Ok "$nobs test(s) named after an OBS signal - the metric is read back" } else { Warn "No test named OBS-0nn - a metric no test covers drifts silently" }
$instrOk = ($tel -and $met -and $rid)

# --- 7. The stack in Azure -----------------------------------------------------------------------
Hdr "7 - The stack in Terraform - Application Insights, the dashboard, alerts"
$stackOk = $false
$otf = Join-Path $inf "observability.tf"
if (Test-Path $otf) {
  $ot = Flat $otf; Ok "infra/observability.tf"
  $n = 0
  if ($ot.Contains('resource "azurerm_application_insights"')) { Ok "Application Insights, on the Log Analytics workspace"; $n++ } else { Warn "No azurerm_application_insights" }
  if ($ot.Contains('resource "azurerm_application_insights_workbook"')) { Ok "A workbook - the dashboard with the business and technical tiles"; $n++ } else { Warn "No workbook - where does the client's number show?" }
  $na = [regex]::Matches($ot, 'resource "azurerm_monitor_(scheduled_query_rules_alert_v2|metric_alert)"').Count
  if ($na -ge 1) { Ok "$na alert rule(s)"; $n++ } else { Warn "No alert rules" }
  if ($ot.Contains('resource "azurerm_monitor_action_group"')) { Ok "An action group - someone hears about it"; $n++ } else { Warn "No action group - an alert nobody receives" }
  if ((Flat $sec).Contains('APPLICATIONINSIGHTS_CONNECTION_STRING')) { Ok "The connection string reaches the app as a secret"; $n++ }
  else { Warn "APPLICATIONINSIGHTS_CONNECTION_STRING is not in local.app_secrets - the app sends nothing (WORKSHOP-S17.md, step 1)" }
  $stackOk = ($n -eq 5)
} elseif (Test-Path "$otf.s17") { Warn "infra/observability.tf.s17 is waiting - Session 17, step 1: rename it to observability.tf" }
else { Warn "No infra/observability.tf - copy the lab's infra-additions/observability.tf (setup-production adds it)" }

# --- 8. The pipeline proves it -------------------------------------------------------------------
Hdr "8 - The pipeline proves it - the telemetry check, the drill, the rollback"
$pipeOk = $false; $jobs = $false; $obsOn = ((PVar 'OBSERVABILITY') -eq 'on')
if (Test-Path $py) {
  if ($obsOn) { Ok "OBSERVABILITY is on - verify:observability is real" } else { Warn "OBSERVABILITY is not `"on`" - verify:observability is still planned (Session 17, step 4)" }
  $missj = ""; foreach ($j in @('verify:observability', 'drill:slow', 'drill:errors', 'drill:clear', 'rollback:test')) { if ($pyText -notmatch "(?m)^$([regex]::Escape($j)):") { $missj += " $j" } }
  if (-not $missj) { Ok "verify:observability, the drill and rollback:test are in the pipeline"; $jobs = $true } else { Warn "Missing from ci/production.yml:$missj" }
}
if ((RowHas 'obs\.version') -and (RowHas 'obs\.business')) { Ok "The strategy has obs.version and obs.business rows" } else { Warn "No obs.version / obs.business rows - the scorecard ignores the telemetry" }
$s6 = (FromLine (Lines $st) '^## 6\.') -join "`n"
if ($s6.Contains('verify:dast') -and $s6.Contains('verify:observability')) { Ok "Section 6 of the strategy draws verify:dast and verify:observability" }
else { Warn "Section 6 of the strategy does not show verify:dast and verify:observability yet" }
$drill = $false
if (Test-Path $os) {
  $dr = @((FromLine (Lines $os) '[Tt]he drill') | Where-Object { $_ -match '^\|\s*(slow|errors)\s*\|' })
  if ($dr.Count -gt 0 -and @($dr | Where-Object { $_ -match 'fill in|\|\s*\|' }).Count -eq 0) { Ok "The drill is recorded: when each alert fired, and the request found by its id"; $drill = $true }
  else { Warn "The drill table in observability.md is not filled in - run it, then write down what happened" }
}
$pipeOk = ($obsOn -and $jobs -and (RowHas 'obs\.business') -and $drill)
git -C $Repo rev-parse -q --verify refs/tags/L6-production 2>$null | Out-Null
$tagged = ($LASTEXITCODE -eq 0)

Hdr "Ready for layer 7? (see BUILD-ROADMAP.md)"
function Bar($yes, $m) { if ($yes) { Write-Host "  [ HAVE ] $m" -ForegroundColor Green } else { Write-Host "  [ NEED ] $m" -ForegroundColor Red; $script:Miss++ } }
Bar $threatOk "A threat model - every threat a control and a proof"
Bar $secOk "Controls tested, named after their threats"
Bar $secretsOk "Secrets from the environment, none in git"
Bar $dastOk "The running service scanned after every deploy"
Bar $obsSpecOk "An observability spec - one business, one technical signal"
Bar $instrOk "The code instrumented - telemetry, the business metric, X-Request-Id"
Bar $stackOk "Application Insights, a dashboard and alerts, in Terraform"
Bar $pipeOk "The pipeline checks the telemetry; the drill run and recorded"
Bar $tagged "Tagged L6-production"
Write-Host ""
if ($script:Miss -eq 0) { Write-Host "  READY - layer 6 is in. Safe to expose, and you can see it run." -ForegroundColor Green }
else { Write-Host "  NOT YET - $($script:Miss) item(s) above." -ForegroundColor Yellow }

Write-Host ""
Write-Host "============================================================"
Write-Host " ok: $($script:Pass)   warnings: $($script:WarnN)   failed: $($script:Fail)"
Write-Host "============================================================"
if ($script:Fail -gt 0) { Write-Host " Something required is missing. Fix the [FAIL] lines and run again."; exit 1 }
if ($script:WarnN -gt 0) { Write-Host " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them." }
exit 0
