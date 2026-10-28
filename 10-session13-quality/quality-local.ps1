# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  quality-local.ps1  -  Session 13: the pipeline's quality gates, on your laptop, before you push
#                        (Windows PowerShell 5.1 / PowerShell 7)
#
#  Runs the same checks as ci/quality.yml - lint, complexity, secrets, SAST, dependencies, IaC -
#  with whichever tools you have installed, and tells you how to get the ones you do not.
#  Writes .quality\local-report.md in your repo (git-ignored): /quality-gates reads it to record
#  today's baseline in specs\design\quality-gates.md.
#
#  USAGE
#    ./quality-local.ps1 -Path "C:\work\group-1" [-App code]
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  Exit code 1 if a gate that blocks in the pipeline has findings - so you can run it before every push.
#  A bash twin (quality-local.sh) exists for macOS / Linux / WSL.
# =============================================================================
param([string]$Path = ".", [string]$App = "")

function Hdr($m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function Have($t) { [bool](Get-Command $t -ErrorAction SilentlyContinue) }
function ReadText($p) { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }

if (-not (Test-Path $Path)) { Write-Host "Path not found: $Path"; exit 1 }
$Repo = (Resolve-Path $Path).Path
Set-Location $Repo
$qaFile = Join-Path $Repo "ci\quality.yml"
$qaText = if (Test-Path $qaFile) { ReadText $qaFile } else { "" }
function QaVar($name) { if ($qaText -match "(?m)^\s+${name}:\s*`"([^`"]*)`"") { $Matches[1] } else { "" } }
if (-not $App) { $App = QaVar 'QA_APP_DIR' }; if (-not $App) { $App = '.' }
$limit = QaVar 'QA_COMPLEXITY_LIMIT'; if (-not $limit) { $limit = '10' }
$baseCx = QaVar 'QA_COMPLEXITY_BASELINE'; $baseIac = QaVar 'QA_IAC_BASELINE'
$stack = ''
if (Test-Path (Join-Path $App 'pom.xml')) { $stack = 'java' }
elseif (Test-Path (Join-Path $App 'package.json')) { $stack = 'node' }
elseif ((Test-Path (Join-Path $App 'pyproject.toml')) -or (Test-Path (Join-Path $App 'requirements.txt'))) { $stack = 'python' }

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Session 13 - quality gates, locally"
Write-Host " $Repo  (app: $App, stack: $(if ($stack) { $stack } else { 'unknown' }))"
Write-Host "============================================================"
New-Item -ItemType Directory -Force -Path (Join-Path $Repo ".quality") | Out-Null
$rows = New-Object System.Collections.Generic.List[string]
$script:Block = $false
function Row($gate, $tool, $result, $blocks, $hint) {
  $rows.Add("| $gate | $tool | $result | $blocks | $hint |")
  if ($result -like 'clean*') { Write-Host "  [ OK ] $gate - $result" -ForegroundColor Green }
  elseif ($result -like 'skipped*') { Write-Host "  [SKIP] $gate - $hint" -ForegroundColor Yellow }
  elseif ($blocks -eq 'yes') { Write-Host "  [FIND] $gate - $result" -ForegroundColor Red; $script:Block = $true }
  else { Write-Host "  [FIND] $gate - $result ($blocks)" -ForegroundColor Yellow }
}
function Count($lines, $pattern) { @($lines | Where-Object { "$_" -match $pattern }).Count }

Hdr "1 - Lint and format (E-010, E-003, E-006)"
switch ($stack) {
  'python' {
    if (Have ruff) {
      $fo = (ruff format --check $App 2>&1 | Out-String)
      $f = if ($fo -match '(?m)^(\d+) files? would be reformatted') { [int]$Matches[1] } else { 0 }
      $l = Count (ruff check $App --output-format=concise 2>$null) '^[^ ].*:\d+:\d+:'
      if (($f + $l) -eq 0) { Row 'Lint' 'ruff' 'clean' 'yes' '' } else { Row 'Lint' 'ruff' "$l finding(s), $f file(s) to reformat" 'yes' "ruff check $App · ruff format $App" }
    } else { Row 'Lint' 'ruff' 'skipped' 'yes' 'pip install ruff' }
  }
  'node' {
    if (Test-Path (Join-Path $App 'node_modules\.bin')) {
      Push-Location $App
      $l = Count (npx --no-install eslint . -f unix 2>$null) ':\d+:\d+:'
      $p = Count (npx --no-install prettier --check . 2>&1) '^\[warn\] [^C]'
      Pop-Location
      if (($l + $p) -eq 0) { Row 'Lint' 'eslint, prettier' 'clean' 'yes' '' } else { Row 'Lint' 'eslint, prettier' "$l finding(s), $p file(s) to format" 'yes' 'npx eslint . · npx prettier --write .' }
    } else { Row 'Lint' 'eslint, prettier' 'skipped' 'yes' "npm ci in $App, with ESLint and Prettier configured" }
  }
  'java' {
    if ((Have mvn) -and ((ReadText (Join-Path $App 'pom.xml')) -match 'spotless|checkstyle')) {
      Push-Location $App; mvn -B -q spotless:check checkstyle:check *> $null; $ok = ($LASTEXITCODE -eq 0); Pop-Location
      if ($ok) { Row 'Lint' 'spotless, checkstyle' 'clean' 'yes' '' } else { Row 'Lint' 'spotless, checkstyle' 'findings' 'yes' 'mvn spotless:apply · mvn checkstyle:check' }
    } else { Row 'Lint' 'spotless, checkstyle' 'skipped' 'yes' 'Maven with Spotless and Checkstyle in pom.xml (Session 10)' }
  }
  default { Row 'Lint' '-' 'skipped' 'yes' "no build file found in $App" }
}

Hdr "2 - Complexity (E-003)"
if (Have lizard) {
  $n = Count (lizard -C $limit -w -x '*/node_modules/*' -x '*/tests/*' -x '*/test/*' -x '*/.claude/*' -x '*/target/*' -x '*/specs/*' $App 2>$null) 'warning:'
  if ($n -eq 0) { Row 'Complexity' 'lizard' 'clean' 'ratchet' "limit $limit" }
  elseif ($baseCx -and $n -le [int]$baseCx) { Row 'Complexity' 'lizard' "$n above $limit - within baseline $baseCx" 'ratchet' '' }
  elseif ($baseCx) { Row 'Complexity' 'lizard' "$n above $limit - baseline is $baseCx" 'yes' "lizard -C $limit -w $App" }
  else { Row 'Complexity' 'lizard' "$n function(s) above $limit" 'no baseline yet' "lizard -C $limit -w $App" }
} else { Row 'Complexity' 'lizard' 'skipped' 'ratchet' 'pip install lizard' }

Hdr "3 - Secrets (E-008)"
if (Have gitleaks) {
  $out = (gitleaks git --redact --no-banner . 2>&1 | Out-String)
  $n = if ($out -match 'leaks found: (\d+)') { [int]$Matches[1] } else { 0 }
  if ($n -eq 0) { Row 'Secrets' 'gitleaks' 'clean' 'yes' '' } else { Row 'Secrets' 'gitleaks' "$n secret(s) in git history" 'yes' 'rotate first, then remove - gitleaks git -v .' }
} else { Row 'Secrets' 'gitleaks' 'skipped' 'yes' 'github.com/gitleaks/gitleaks/releases - or winget / scoop' }

Hdr "4 - Static analysis - SAST"
if (Have semgrep) {
  $sj = Join-Path $Repo ".quality\semgrep.json"
  semgrep scan --config p/default --metrics off --exclude specs --exclude .claude --quiet --json -o $sj . *> $null
  $j = if (Test-Path $sj) { ReadText $sj } else { "" }
  $e = ([regex]::Matches($j, '"severity":\s*"ERROR"')).Count; $w = ([regex]::Matches($j, '"severity":\s*"WARNING"')).Count
  if ($e -eq 0 -and $w -eq 0) { Row 'SAST' 'semgrep' 'clean' 'yes' 'severity ERROR blocks' }
  elseif ($e -eq 0) { Row 'SAST' 'semgrep' "$w warning(s)" 'reported' 'semgrep scan --config p/default .' }
  else { Row 'SAST' 'semgrep' "$e error(s), $w warning(s)" 'yes' 'semgrep scan --config p/default .' }
} else { Row 'SAST' 'semgrep' 'skipped' 'yes' 'Windows: run it in WSL or Docker (semgrep/semgrep:1.182.1)' }

Hdr "5 - Dependencies"
if (Have osv-scanner) {
  $oj = Join-Path $Repo ".quality\osv.json"
  osv-scanner scan source -r --format json $App 2>$null | Out-File -Encoding utf8 $oj; $rc = $LASTEXITCODE
  $ids = @([regex]::Matches((ReadText $oj), '"id":\s*"((GHSA|PYSEC|CVE|RUSTSEC|GO)-[^"]*)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
  if ($rc -eq 128) { Row 'Dependencies' 'osv-scanner' 'no lockfile or pinned requirements' 'yes' 'pin your dependencies' }
  elseif ($rc -eq 0) { Row 'Dependencies' 'osv-scanner' 'clean' 'yes' '' }
  else { Row 'Dependencies' 'osv-scanner' "$($ids.Count) known vulnerabilit(ies)" 'yes' "osv-scanner scan source -r $App" }
} else { Row 'Dependencies' 'osv-scanner' 'skipped' 'yes' 'github.com/google/osv-scanner/releases - or winget' }

Hdr "6 - Infrastructure as code"
if (Test-Path (Join-Path $Repo 'infra\*.tf')) {
  if (Have checkov) {
    $co = (checkov -d infra --framework terraform --compact --quiet 2>$null | Out-String)
    $n = if ($co -match 'Failed checks: (\d+)') { [int]$Matches[1] } else { 0 }
    if ($n -eq 0) { Row 'IaC' 'checkov' 'clean' 'ratchet' '' }
    elseif ($baseIac -and $n -le [int]$baseIac) { Row 'IaC' 'checkov' "$n failed - within baseline $baseIac" 'ratchet' '' }
    elseif ($baseIac) { Row 'IaC' 'checkov' "$n failed - baseline is $baseIac" 'yes' 'checkov -d infra --compact' }
    else { Row 'IaC' 'checkov' "$n failed check(s)" 'no baseline yet' 'checkov -d infra --compact' }
  } else { Row 'IaC' 'checkov' 'skipped' 'ratchet' 'pip install checkov' }
} else { Row 'IaC' 'checkov' 'clean - no infra/*.tf yet' 'ratchet' '' }

$branch = (git rev-parse --abbrev-ref HEAD 2>$null); $commit = (git rev-parse --short HEAD 2>$null)
$report = @("# Local quality report", "", "*$(Get-Date -Format 'yyyy-MM-dd HH:mm') · branch $branch · commit $commit · app $App · complexity limit $limit*", "",
            "| Gate | Tool | Result | Blocks in CI | How to look |", "|---|---|---|---|---|") + $rows +
          @("", "Not committed. ``/quality-gates`` reads it to record the baseline in ``specs/design/quality-gates.md``.")
[System.IO.File]::WriteAllText((Join-Path $Repo ".quality\local-report.md"), (($report -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding $false))

Write-Host ""
Write-Host "============================================================"
Write-Host " Report: .quality/local-report.md"
if ($script:Block) {
  Write-Host " A gate that blocks in the pipeline has findings. Fix, or triage with /triage-findings, before you push." -ForegroundColor Red
  Write-Host "============================================================"; exit 1
}
Write-Host " Nothing that blocks. Skipped tools still run in the pipeline." -ForegroundColor Green
Write-Host "============================================================"
exit 0
