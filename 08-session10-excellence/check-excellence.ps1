# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-excellence.ps1  -  Session 10, layer 2: is the code shaped well,
#                           and did the spec change first?
#                           (Windows PowerShell 5.1 / PowerShell 7)
#
#  Checks structure, rules, review decisions and git discipline - never whether
#  the design is good. That is what the review and the debrief are for.
#
#  USAGE
#    ./check-excellence.ps1 -Path "C:\work\group-1" [-Slice "specs\001-first-slice"]
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  Exit code is non-zero only if something required is missing.
#  A bash twin (check-excellence.sh) exists for macOS / Linux / WSL.
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
function Section($lines, $head) {
  $out = @(); $on = $false
  foreach ($l in $lines) {
    if ($l.StartsWith($head)) { $on = $true; continue }
    if ($l -match '^## ') { $on = $false }
    if ($on) { $out += $l }
  }
  $out
}

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
Write-Host " Junior SWAT Labs - Session 10 - layer 2 check"
Write-Host " $Repo"
Write-Host "============================================================"

if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository"; exit 1 }
$SpecP = $null; if ($SliceDir) { $SpecP = Join-Path $SliceDir "spec.md" }
if (-not $SpecP -or -not (Test-Path $SpecP)) { Bad "No slice spec found (specs/NNN-name/spec.md) - Session 9 comes first"; exit 1 }
$sliceName = Split-Path $SliceDir -Leaf
Ok "Slice: specs/$sliceName"
$S = Lines $SpecP; $C = Lines (Join-Path $Repo "constitution.md"); $P = Lines (Join-Path $SliceDir "plan.md")

# Source and test files - everything outside the spec, docs and lab scaffolding
$excl = '[\\/](specs|docs|templates|prompts|\.claude|\.git|\.gitlab|node_modules|target|build|dist|\.venv|venv|__pycache__|examples)[\\/]'
$src = @(Get-ChildItem $Repo -Recurse -File -Include *.py,*.java,*.kt,*.js,*.ts,*.cs,*.go -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName.Substring($Repo.Length) -notmatch $excl })
$tst = @($src | Where-Object { ($_.FullName.Substring($Repo.Length) -replace '\\','/') -match '(?i)(/tests?/|/test_[^/]*$|_test\.[a-z]+$|Tests?\.(java|kt|cs)$|\.(test|spec)\.(js|ts)$)' })
function Rel($f) { $f.FullName.Substring($Repo.Length + 1) -replace '\\','/' }

# --- 1. The spec changed first ---------------------------------------------------
Hdr "1 - The spec changed first"
$s5 = @(Section $C "## 5.")
$erows = @($s5 | Where-Object { $_ -match '^\|\s*E-\d{3}' -and (Cell $_ 2) -ne "" })
$ne = $erows.Count
$nechk = @($erows | Where-Object { (Cell $_ 3) -ne "" }).Count
if ($s5.Count -eq 0) { Bad "constitution.md has no section 5 - engineering rules. Run /spec-engineering-rules" }
elseif ($ne -lt 3) { Warn "Only $ne engineering rule(s) in section 5 - pick five to seven" }
else { Ok "$ne engineering rules in constitution section 5" }
if ($ne -gt 0) {
  if ($nechk -eq $ne) { Ok "Every engineering rule says how it is checked" }
  else { Warn "$($ne - $nechk) rule(s) with no 'Checked by' - a rule nobody checks is a wish" }
}
if ($ne -gt 7) { Warn "$ne engineering rules - will you really check all of them?" }

$s12 = @(Section $P "## 12.")
$comp = @($s12 | Where-Object { $_ -match '^\|' -and $_ -notmatch '^\|\s*(Component|-+)\s*\|' -and (Cell $_ 1) -ne "" -and (Cell $_ 2) -ne "" })
$ncomp = $comp.Count
if ($s12.Count -eq 0) { Bad "plan.md has no section 12 - components. Run /spec-components" }
elseif ($ncomp -lt 2) { Warn "Section 12 has $ncomp component(s) - is the slice really one piece?" }
else { Ok "$ncomp components in plan section 12" }
$and = @($comp | Where-Object { (Cell $_ 2) -match '(?i)\band\b' }).Count
if ($ncomp -gt 0) {
  if ($and -eq 0) { Ok "Every component's job is said without 'and'" }
  else { Warn "$and component(s) need 'and' to say their job - E-002 says split them:"; $comp | Where-Object { (Cell $_ 2) -match '(?i)\band\b' } | ForEach-Object { Write-Host ("           " + (Cell $_ 1)) } }
}
$s12t = $s12 -join "`n"
if ($s12.Count -eq 0) { }
elseif ($s12t -match '(?m)^```mermaid' -and $s12t -match 'classDiagram') {
  if ($s12t -match 'class (UseCase|Rule|SomePort|SomeAdapter)\b') { Warn "The class diagram still holds the template's placeholder classes" }
  else { Ok "Class diagram, as code" }
} else { Warn "No Mermaid classDiagram in section 12" }

# --- 2. The code -------------------------------------------------------------------
Hdr "2 - The code"
if ($src.Count -eq 0) { Bad "No code yet - /build-tasks generates the first tasks" }
else { Ok "$($src.Count) source file(s), of which $($tst.Count) test file(s)" }
if ($src.Count -gt 0 -and $tst.Count -eq 0) { Warn "No test files - W-003 says the test comes first" }
if ($tst.Count -gt 0) {
  $tt = (($tst | ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }) -join "`n").ToUpper().Replace('_','-')
  $ids = @(([regex]::Matches(($S -join "`n"), '\b(FR|RULE)-\d{3}\b') | ForEach-Object { $_.Value } | Sort-Object -Unique))
  $miss = @($ids | Where-Object { $tt -notmatch [regex]::Escape($_) })
  if ($miss.Count -eq 0) { Ok "Every FR and RULE is named by a test (E-009)" }
  else { Warn ("No test names: " + ($miss -join ' ') + " - fine if not built yet; say which at the debrief") }
}
if ($src.Count -gt 0) {
  $secretRx = '(?i)(password|passwd|secret|api[_-]?key|token)[A-Za-z_]*\s*[:=]\s*["''][^"'']{4,}|-----BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16}'
  $secrets = @($src | Select-String -Pattern $secretRx | Select-Object -First 5)
  if ($secrets.Count -eq 0) { Ok "No obvious secrets in code (the pipeline's gitleaks scan looks deeper)" }
  else { Warn "Looks like a secret in code (W-004, E-008):"; $secrets | ForEach-Object { Write-Host ("           " + (Rel (Get-Item $_.Path)) + ":" + $_.LineNumber + "  (value hidden)") } }
  $catchRx = 'except( Exception)?:\s*(pass|return None)?\s*$|catch\s*\([^)]*\)\s*\{\s*\}'
  $catches = @($src | Select-String -Pattern $catchRx -CaseSensitive | Select-Object -First 5)
  if ($catches.Count -eq 0) { Ok "No obvious catch-all that hides errors" }
  else { Warn "Catch-all that may hide a failure (E-006, W-006):"; $catches | ForEach-Object { Write-Host ("           " + (Rel (Get-Item $_.Path)) + ":" + $_.LineNumber + ":" + $_.Line.Trim()) } }
}
if (Test-Path (Join-Path $Repo ".gitlab-ci.yml")) { Ok ".gitlab-ci.yml present - the rules run as checks" }
else { Warn "No .gitlab-ci.yml - a rule in the pipeline beats a rule in a reminder (ci/ has starters)" }

# --- 3. Review and debt ------------------------------------------------------------
Hdr "3 - Review, decisions and debt"
$rev = Get-ChildItem (Join-Path $SliceDir "reviews") -Filter "*review*.md" -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1
$undec = 1
if (-not $rev) { Bad "No review in specs/$sliceName/reviews/ - run /review-excellence" }
else {
  $rows = @((Lines $rev.FullName) | Where-Object { $_ -match '^\|\s*\d+\s*\|' })
  $nf = $rows.Count
  Ok ("Review: " + (Rel $rev) + " - $nf finding(s)")
  if ($nf -gt 0) {
    $norule = @($rows | Where-Object { (Cell $_ 3) -notmatch '\b[EW]-\d{3}\b' }).Count
    if ($norule -eq 0) { Ok "Every finding names a rule" } else { Warn "$norule finding(s) name no rule - no rule, no finding" }
    $undec = @($rows | Where-Object { (Cell $_ 7) -eq "" }).Count
    if ($undec -eq 0) { Ok "Every finding decided by the group" } else { Warn "$undec finding(s) not decided yet - fix, debt, or overruled with a reason" }
    $ovr = @($rows | Where-Object { (Cell $_ 7) -match '(?i)overrul' -and (Cell $_ 7).Length -lt 25 }).Count
    if ($ovr -gt 0) { Warn "$ovr overruled finding(s) with no real reason - say why" }
    $fix = @($rows | Where-Object { (Cell $_ 7) -match '(?i)fix' }).Count
    $dbt = @($rows | Where-Object { (Cell $_ 7) -match '(?i)debt' }).Count
    $ov = @($rows | Where-Object { (Cell $_ 7) -match '(?i)overrul' }).Count
    Write-Host "         decisions: $fix fix - $dbt debt - $ov overruled"
  } else { $undec = 0 }
}
$debtP = Join-Path $Repo "specs\design\tech-debt.md"
if (-not (Test-Path $debtP)) { Warn "No specs/design/tech-debt.md - setup-excellence adds it" }
else {
  $td = @((Lines $debtP) | Where-Object { $_ -match '^\|\s*TD-\d{3}' -and (Cell $_ 2) -ne "" })
  Ok "Debt register: $($td.Count) item(s)"
  $nopay = @($td | Where-Object { (Cell $_ 7) -eq "" }).Count
  if ($td.Count -gt 0 -and $nopay -gt 0) { Warn "$nopay debt item(s) with no 'Pay back by' - debt with no date is a surprise" }
}

# --- 4. Git discipline -------------------------------------------------------------
Hdr "4 - Branches, commits and the tag"
$cc = @(git -C $Repo log --no-merges --format='%h %s' -- '*.py' '*.java' '*.kt' '*.js' '*.ts' '*.cs' '*.go' ':!specs/**' ':!docs/**' ':!templates/**' ':!examples/**' ':!.claude/**' 2>$null | Where-Object { $_ })
$not = @($cc | Where-Object { $_ -notmatch 'T\d{3}|refactor:|finding' }).Count
if ($cc.Count -eq 0) { Warn "No commits touch code yet" }
elseif ($not -eq 0) { Ok "All $($cc.Count) code commit(s) name a task or a finding (W-002, E-012)" }
else { Warn "$not of $($cc.Count) code commit(s) name no task ID - e.g. 'T006: build the matcher (FR-003)'" }
$nmerge = @(git -C $Repo log --merges --oneline 2>$null | Where-Object { $_ }).Count
if ($nmerge -ge 1) { Ok "$nmerge merge(s) - work arrived through a merge request" } else { Warn "No merges yet - code goes to main through a merge request" }
git -C $Repo rev-parse -q --verify "refs/tags/L2-design" 2>$null | Out-Null
$tagged = ($LASTEXITCODE -eq 0)
if ($tagged) { Ok "Tag L2-design" } else { Warn "No tag L2-design yet - tag main when layer 2 is merged" }
$pushed = $false
git -C $Repo rev-parse --abbrev-ref '@{u}' 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $pushed = ([int](git -C $Repo rev-list --count '@{u}..HEAD' 2>$null) -eq 0) }
if ($pushed) { Ok "Everything on this branch is pushed" } else { Warn "Not pushed - push before you leave" }

# --- Ready for layer 3? -------------------------------------------------------------
Hdr "Ready for layer 3? (see BUILD-ROADMAP.md)"
$script:Miss = 0
function Bar($have, $m) { if ($have) { Write-Host "  [ HAVE ] $m" -ForegroundColor Green } else { Write-Host "  [ NEED ] $m" -ForegroundColor Red; $script:Miss++ } }
Bar ($ne -ge 3 -and $nechk -eq $ne) "Engineering rules in the constitution, each with a check"
Bar ($ncomp -ge 2) "Components in plan section 12"
Bar ($src.Count -gt 0 -and $tst.Count -gt 0) "Code for the first tasks, with tests"
Bar ($rev -and $undec -eq 0) "A review with every finding decided"
Bar $tagged "Tagged L2-design"
Bar $pushed "Pushed to your GitLab project"
Write-Host ""
if ($script:Miss -eq 0) { Write-Host "  READY - layer 2 is in. Layer 3 builds on it." -ForegroundColor Green }
else { Write-Host "  NOT YET - $($script:Miss) item(s) above." -ForegroundColor Yellow }

Write-Host ""
Write-Host "============================================================"
Write-Host (" ok: {0}   warnings: {1}   failed: {2}" -f $script:Pass, $script:WarnN, $script:Fail)
Write-Host "============================================================"
if ($script:Fail -gt 0) { Write-Host " Something required is missing. Fix the [FAIL] lines and run again."; exit 1 }
if ($script:WarnN -gt 0) { Write-Host " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them." }
exit 0
