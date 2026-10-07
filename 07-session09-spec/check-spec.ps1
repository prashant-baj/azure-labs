# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-spec.ps1  -  Session 9: is this spec one a team could build from?
#                     (Windows PowerShell 5.1 / PowerShell 7)
#
#  Checks structure, IDs, sources and traceability - never the quality of your
#  thinking. That is what the debrief is for.
#
#  USAGE
#    ./check-spec.ps1 -Path "C:\work\group-1" [-Slice "specs\001-first-slice"]
#      -Slice defaults to the highest-numbered specs\NNN-* folder
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  Exit code is non-zero if any REQUIRED check fails.
#  A bash twin (check-spec.sh) exists for macOS / Linux / WSL.
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
function Lines($p) { if (Test-Path $p) { [System.IO.File]::ReadAllLines($p, [System.Text.Encoding]::UTF8) } else { @() } }

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
$SpecP = $null; $PlanP = $null; $TasksP = $null
if ($SliceDir) { $SpecP = Join-Path $SliceDir "spec.md"; $PlanP = Join-Path $SliceDir "plan.md"; $TasksP = Join-Path $SliceDir "tasks.md" }
$ConstP = Join-Path $Repo "constitution.md"

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Session 9 - spec check"
Write-Host " $Repo"
Write-Host "============================================================"

$Placeholder = '<[a-zA-Z.][^>]*>'
# table rows whose first cell is an ID with the prefix; template placeholder rows excluded
function Rows($lines, $prefix) { $lines | Where-Object { $_ -match "^\|\s*$prefix-\d{3}[a-z]?\s*\|" -and $_ -notmatch $Placeholder } }
function Cell($row, $n) { $c = $row.Split('|'); if ($c.Count -gt $n) { $c[$n].Trim() } else { "" } }
function Filled($lines, $prefix) { @(Rows $lines $prefix | Where-Object { (Cell $_ 2) -ne "" }) }
function Ids($lines, $prefix) { @(($lines -join "`n") | Select-String -Pattern "\b$prefix-\d{3}\b" -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value } | Sort-Object -Unique) }
function Section($lines, $head) {
  $out = @(); $on = $false
  foreach ($l in $lines) {
    if ($l.StartsWith($head)) { $on = $true; continue }
    if ($l -match '^## ') { $on = $false }
    if ($on) { $out += $l }
  }
  $out
}
$TechRx = '\b(Java|Spring|Python|FastAPI|Django|Flask|Node\.?js|Express|NestJS|React|Angular|\.NET|C#|Kafka|RabbitMQ|Redis|Postgres|PostgreSQL|MySQL|MongoDB|Cosmos|SQL Server|Azure|AWS|GCP|Docker|Kubernetes|AKS|REST|GraphQL|JSON|XML|gRPC|Service Bus|Event Grid|Lambda|microservice)s?\b'

# --- Structure ----------------------------------------------------------------
Hdr "The four layers"
if (Test-Path (Join-Path $Repo ".git")) { Ok "It is a git repository" } else { Bad "Not a git repository" }
if (Test-Path (Join-Path $Repo "docs")) { Ok "docs/ - the evidence" } else { Warn "docs/ missing - layer 1, the evidence" }
if (Test-Path $ConstP) { Ok "constitution.md" } else { Bad "constitution.md missing - run organise-specs first" }
if (Test-Path (Join-Path $specsDir "README.md")) { Ok "specs/README.md" } else { Warn "specs/README.md missing" }
$designDir = Join-Path $specsDir "design"
if (Test-Path $designDir) {
  $missing = @("solution-definition.md","integration-decisions.md","nfr-register.md","constraints.md","contracts","adr") | Where-Object { -not (Test-Path (Join-Path $designDir $_)) }
  if (-not $missing) { Ok "specs/design/ holds the whole Module 2 record" } else { Warn ("specs/design/ is missing: " + ($missing -join ' ')) }
} else { Bad "specs/design/ missing - run organise-specs first" }
$ncmd = @(Get-ChildItem (Join-Path $Repo ".claude\commands\spec-*.md") -ErrorAction SilentlyContinue).Count
if ($ncmd -ge 6) { Ok "$ncmd /spec- commands in .claude/commands/" } else { Warn "Only $ncmd /spec- commands found in .claude/commands/" }

if (-not $SliceDir -or -not (Test-Path $SliceDir)) { Bad "No slice folder (specs/NNN-name/) found"; Write-Host ""; Write-Host "Stopping."; exit 1 }
Ok ("Slice: specs/" + (Split-Path $SliceDir -Leaf))
if (-not (Test-Path $SpecP)) { Bad "spec.md missing in the slice folder"; Write-Host ""; Write-Host "Stopping."; exit 1 }

# --- Constitution ---------------------------------------------------------------
Hdr "Constitution"
$C = Lines $ConstP
if ($C.Count -gt 0) {
  if (($C -join "`n") -match '<case name>|<date>|<names>') { Bad "Template placeholders still in constitution.md" } else { Ok "Placeholders replaced" }
  $cr = Filled $C "C"; $qr = Filled $C "Q"
  if ($cr.Count -ge 1) { Ok "$($cr.Count) rule(s) you were handed" } else { Warn "No rules in section 2 - every enterprise hands you some" }
  if ($qr.Count -ge 1) { Ok "$($qr.Count) quality floor(s)" } else { Warn "No quality floors in section 3" }
  $nosrc = @($cr | Where-Object { (Cell $_ 3) -eq "" }).Count + @($qr | Where-Object { (Cell $_ 4) -eq "" }).Count
  if ($nosrc -eq 0) { Ok "Every filled rule has a source" } else { Warn "$nosrc rule(s) with no source - a rule with no source is an opinion" }
  $w = (Ids $C "W").Count
  if ($w -ge 6) { Ok "House rules W-001 to W-006 kept" } else { Warn "Only $w house rule(s) - W-001 to W-006 were meant to stay" }
}

# --- Spec -----------------------------------------------------------------------
Hdr "Spec - what and why"
$S = Lines $SpecP
$s0 = Section $S "## 0." | Where-Object { $_.Trim() -ne "" -and $_ -notmatch '^\s*(<!--|Written|One paragraph|coding hours|-->)' }
if (-not $s0 -or (($s0 -join "`n") -match '<One paragraph\.>')) { Bad "Section 0 is empty - the group writes it by hand, first" } else { Ok "Section 0 written" }

$fr = Filled $S "FR"; $in = Filled $S "IN"; $rule = Filled $S "RULE"; $nfr = Filled $S "NFR"
if ($fr.Count -eq 0) { Bad "No functional requirements (FR-001 ...)" }
elseif ($fr.Count -gt 15) { Warn "$($fr.Count) functional requirements - is this a slice, or a platform?" }
else { Ok "$($fr.Count) functional requirement(s)" }
if ($fr.Count -gt 0) {
  $noshall = @($fr | Where-Object { (Cell $_ 2) -notmatch 'shall' }).Count
  if ($noshall -eq 0) { Ok "Every FR uses 'shall'" } else { Warn "$noshall FR row(s) without 'shall' - EARS form, please" }
}
if (@($fr | Where-Object { (Cell $_ 2) -match '^If .*then the system shall' }).Count -ge 1) { Ok "At least one 'If ... then' requirement - the case nobody writes" }
else { Warn "No 'If <unwanted case>, then the system shall ...' requirement - what happens when it goes wrong?" }
if ($in.Count -ge 2) { Ok "$($in.Count) inputs described" }
elseif ($in.Count -eq 1) { Warn "Only one input - does everything really come from one place?" }
else { Warn "Section 3 (what comes in) is empty" }
if ($rule.Count -ge 1) { Ok "$($rule.Count) worked example(s) of the rule" } else { Warn "No worked examples for the rule in section 5 - given this, expect that" }
if ($nfr.Count -ge 1) { Ok "$($nfr.Count) quality requirement(s) for this slice" } else { Warn "No quality requirements in section 8" }

$nosrc = @($fr | Where-Object { (Cell $_ 3) -eq "" }).Count + @($in | Where-Object { (Cell $_ 6) -eq "" }).Count `
       + @($rule | Where-Object { (Cell $_ 4) -eq "" }).Count + @($nfr | Where-Object { (Cell $_ 5) -eq "" }).Count
if ($nosrc -eq 0) { Ok "Every row has a source" } else { Warn "$nosrc row(s) with no source - where did it come from?" }

$body = ($S | Where-Object { $_ -notmatch '^<!--' }) -join "`n"
$tech = @([regex]::Matches($body, $TechRx) | ForEach-Object { $_.Value } | Sort-Object -Unique)
if ($tech.Count -eq 0) { Ok "No technology names in the spec" } else { Warn ("Technology in the spec: " + ($tech -join ' ') + " - that belongs in plan.md") }
$vague = @([regex]::Matches($body, '(?i)\b(fast|quickly|timely|user.friendly|seamless|real.time|as required|appropriate|robust)\b') | ForEach-Object { $_.Value.ToLower() } | Sort-Object -Unique)
if ($vague.Count -eq 0) { Ok "No words that cannot fail" } else { Warn ("Words that cannot fail: " + ($vague -join ' ') + " - run /spec-clarify") }
$nnc = @($S | Where-Object { $_ -match 'NEEDS CLARIFICATION' -and $_ -notmatch '<question>' }).Count
if ($nnc -eq 0) { Ok "No open [NEEDS CLARIFICATION] markers" }
else {
  $who = @(Section $S "## 10." | Where-Object { $_ -match '^\|\s*\d+' -and (Cell $_ 3) -ne "" }).Count
  Warn "$nnc line(s) with [NEEDS CLARIFICATION] - fine, if each is in section 10 with who can answer ($who named)"
}

# --- Architecture and stack -------------------------------------------------------
Hdr "Architecture and stack - what we build with"
$adrDir = Join-Path $Repo "specs\design\adr"
$AdrF = Get-ChildItem $adrDir -Filter "*architecture*.md" -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1
if (-not $AdrF) { Warn "No architecture-and-stack ADR in specs/design/adr/ - /spec-architecture, then decide as a group" }
else {
  $A = Lines $AdrF.FullName
  $adrRel = "specs/design/adr/" + $AdrF.Name
  Ok "ADR: $adrRel"
  $nopt = @(Section $A "## 2." | Where-Object { $_ -match '^\|\s*[A-E]\s*\|' -and (Cell $_ 2) -ne "" }).Count
  if ($nopt -ge 2) { Ok "$nopt architecture options compared" } else { Warn "Fewer than two architecture options - a choice needs something to choose between" }
  $ndrv = @(Section $A "## 1." | Where-Object { $_ -match '^\|' -and $_ -notmatch '^\|\s*(Driver|-+)\s*\|' -and $_ -notmatch $Placeholder -and (Cell $_ 2) -ne "" }).Count
  if ($ndrv -ge 3) { Ok "$ndrv drivers named" } else { Warn "Only $ndrv driver(s) filled - the options are compared against these" }
  $atext = $A -join "`n"
  $weWill = @(Section $A "## 4." | Where-Object { $_ -match '^We will' }).Count
  if ($atext -match 'DECISION NEEDED' -or $atext -match '(?i)Status:\s*proposed' -or $weWill -eq 0) { Warn "Not decided yet - the group writes the 'We will ...' sentence in section 4 and sets Status: accepted" }
  else { Ok "Decided by the group, and accepted" }
  git -C $Repo ls-files --error-unmatch $adrRel 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok "ADR committed" } else { Warn "ADR not committed yet - adr: architecture and stack" }
}

# --- Plan -----------------------------------------------------------------------
Hdr "Plan - how"
$P = Lines $PlanP
if ($P.Count -eq 0 -or (($P -join "`n") -match '<How the slice works')) { Warn "plan.md not written yet - /spec-plan" }
else {
  Ok "plan.md written"
  $cc = @(Section $P "## 2. Constitution check" | Where-Object { $_ -match '^\|' -and $_ -notmatch '^\|\s*(Rule|-+)\s*\|' -and (Cell $_ 1) -ne "" }).Count
  if ($cc -ge 1) { Ok "Constitution check has $cc row(s)" } else { Warn "Constitution check is empty" }
  $ptext = $P -join "`n"
  $miss = @(Ids $S "FR" | Where-Object { $ptext -notmatch [regex]::Escape($_) })
  if ($miss.Count -eq 0) { Ok "Every FR has a home in the plan" } else { Warn ("FR with no home in the plan: " + ($miss -join ' ')) }
  $badlink = @([regex]::Matches($ptext, 'contracts/[A-Za-z0-9._-]+\.md') | ForEach-Object { $_.Value } | Sort-Object -Unique | Where-Object { -not (Test-Path (Join-Path $designDir $_)) })
  if ($badlink.Count -eq 0) { Ok "Every contract the plan links exists" } else { Warn ("Plan links contracts that do not exist: " + ($badlink -join ' ')) }
  $s8 = @(Section $P "## 8."); $h8 = @($P | Where-Object { $_ -match '^## 8\.' })
  if ($s8 | Where-Object { $_ -match '^\|\s*Language\s*\|\s*\|' }) { Warn "Section 8 is still empty - copy the decision from the ADR" }
  elseif ($AdrF -and ((($h8 + $s8) -join "`n") -match ([regex]::Escape($AdrF.Name.Substring(0,4)) + '|architecture-and-stack'))) { Ok "Section 8 applies the stack from the ADR" }
  else { Warn "Section 8 does not point at the architecture-and-stack ADR" }
  $nmer = @($P | Where-Object { $_ -match '^```mermaid' }).Count
  if ($ptext -match '<this slice>') { Warn "Diagrams in section 11 still hold template placeholders" }
  elseif ($nmer -ge 2) { Ok "$nmer diagrams as code in the plan" }
  elseif ($nmer -eq 1) { Warn "Only one diagram - an area map and a sequence with its failure path are both expected" }
  else { Warn "No diagrams as code (mermaid) in plan.md section 11" }
  if ($nmer -ge 1 -and -not ($P | Where-Object { $_ -match '^\s*(alt|opt)\b' })) { Warn "The sequence diagram shows no failure branch (alt / opt)" }
  $inf = @($P | Where-Object { $_ -match '\(inferred\)' }).Count
  if ($inf -gt 0) { Ok "$inf line(s) marked (inferred) - read them aloud before you accept them" }
}

# --- Tasks ----------------------------------------------------------------------
Hdr "Tasks - in what order"
$T = Lines $TasksP
$tl = @($T | Where-Object { $_ -match '^- \[[ xX]\] T\d{3}' -and $_ -notmatch $Placeholder })
if ($tl.Count -eq 0) { Warn "tasks.md has no tasks yet - /spec-tasks" }
else {
  if ($tl.Count -gt 25) { Warn "$($tl.Count) tasks - more than twenty-five usually means the slice is too big" } else { Ok "$($tl.Count) task(s)" }
  $noid = @($tl | Where-Object { $_ -notmatch '\b(FR|IN|RULE|NFR|C|Q|W)-\d{3}' }).Count
  if ($noid -eq 0) { Ok "Every task names a requirement ID" } else { Warn "$noid task(s) name no requirement - why do they exist?" }
  $ntest = @($tl | Where-Object { $_ -match '(?i)\btests?\b' }).Count
  if ($ntest -ge 1) { Ok "$ntest test task(s)" } else { Warn "No test tasks - W-003 says tests come first" }
  $ttext = $T -join "`n"
  $miss = @((Ids $S "FR") + (Ids $S "RULE") | Where-Object { $ttext -notmatch [regex]::Escape($_) })
  if ($miss.Count -eq 0) { Ok "Every FR and RULE has a task" } else { Warn ("No task for: " + ($miss -join ' ') + " - it will not get built") }
  $stext = $S -join "`n"
  $ghost = @([regex]::Matches(($tl -join "`n"), '\b(FR|RULE|IN|NFR)-\d{3}\b') | ForEach-Object { $_.Value } | Sort-Object -Unique | Where-Object { $stext -notmatch [regex]::Escape($_) })
  if ($ghost.Count -eq 0) { Ok "Every ID in tasks exists in the spec" } else { Warn ("Tasks name IDs the spec does not have: " + ($ghost -join ' ')) }
}
if (Test-Path (Join-Path $SliceDir "trace.md")) { Ok "trace.md present" } else { Warn "No trace.md - run /spec-trace and read the gaps together" }

# --- Git ------------------------------------------------------------------------
Hdr "Commit discipline and the remote"
if (Test-Path (Join-Path $Repo ".git")) {
  $rel = "specs/" + (Split-Path $SliceDir -Leaf)
  $sc = [int](git -C $Repo rev-list --count HEAD -- "$rel/spec.md" 2>$null)
  if ($sc -ge 2) { Ok "$sc commits touch spec.md (section 0 by hand first, then the rest)" }
  else { Warn "Only $sc commit(s) touch spec.md - was section 0 committed before the assistant saw it?" }
  foreach ($f in @("plan","tasks")) {
    $n = [int](git -C $Repo rev-list --count HEAD -- "$rel/$f.md" 2>$null)
    if ($n -ge 2) { Ok "$f.md committed after it was filled" } else { Warn "$f.md has not been committed since the template" }
  }
  $url = git -C $Repo remote get-url origin 2>$null
  if (-not $url) { Warn "No remote - run connect-gitlab before you leave" }
  else {
    if ($url -match 'gitlab\.stackroute\.in') { Ok "Remote is your GitLab project" } else { Warn "Remote is not on gitlab.stackroute.in: $url" }
    git -C $Repo rev-parse --abbrev-ref '@{u}' 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
      $ahead = [int](git -C $Repo rev-list --count '@{u}..HEAD' 2>$null)
      if ($ahead -eq 0) { Ok "Everything is pushed" } else { Warn "$ahead commit(s) not pushed yet" }
    } else { Warn "Branch has no upstream - push with connect-gitlab" }
  }
}

Write-Host ""
Write-Host "============================================================"
Write-Host (" ok: {0}   warnings: {1}   failed: {2}" -f $script:Pass, $script:WarnN, $script:Fail)
Write-Host "============================================================"
if ($script:Fail -gt 0) { Write-Host " Something required is missing. Fix the [FAIL] lines and run again."; exit 1 }
if ($script:WarnN -gt 0) { Write-Host " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them." }
exit 0
