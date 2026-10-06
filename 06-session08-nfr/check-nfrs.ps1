<#
  MindSprint Junior SWAT Engineering Program 2026 - Labs
  check-nfrs.ps1  -  Session 8 NFR register and constraints  (PowerShell)
  USAGE:  ./check-nfrs.ps1 -Path "C:\work\group-1"
  A bash twin (check-nfrs.sh) exists for macOS / Linux / WSL.
#>
[CmdletBinding()] param([string]$Path = ".")
$script:Pass = 0; $script:Warn = 0; $script:Fail = 0
function Write-Ok   { param($m) Write-Host "  [ OK ] $m" -ForegroundColor Green;  $script:Pass++ }
function Write-Warn { param($m) Write-Host "  [WARN] $m" -ForegroundColor Yellow; $script:Warn++ }
function Write-Bad  { param($m) Write-Host "  [FAIL] $m" -ForegroundColor Red;    $script:Fail++ }
function Write-Hdr  { param($m) Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function Get-Section { param([string[]]$Lines,[string]$Pattern)
  $out=@(); $in=$false
  foreach ($l in $Lines) {
    if ($l -match $Pattern) { $in=$true; continue }
    if ($in -and $l -match '^##\s') { break }
    if ($in) { $out += $l }
  }
  return $out
}
function Write-Summary {
  Write-Host ""
  Write-Host "============================================================"
  Write-Host " ok: $script:Pass   warnings: $script:Warn   failed: $script:Fail"
  Write-Host "============================================================"
  if ($script:Fail -gt 0) { Write-Host " Something required is missing. Fix the [FAIL] lines and run again."; exit 1 }
  if ($script:Warn -gt 0) {
    Write-Host " Nothing is broken. Read the warnings and decide - they are judgement calls,"
    Write-Host " and at the debrief you will be asked about them."
  }
  exit 0
}

$repo = $Path
$reg  = Join-Path $repo 'specs\nfr-register.md'
$con  = Join-Path $repo 'specs\constraints.md'
Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Session 8 - requirements and constraints"
Write-Host " $repo"
Write-Host "============================================================"
if (-not (Test-Path $repo)) { Write-Bad "Path not found: $repo"; exit 1 }

function Get-Rows { param($file)
  if (-not (Test-Path $file)) { return @() }
  Get-Content $file | Where-Object { $_ -match '^\|' -and $_ -notmatch '(?i)^\|\s*(Family|Constraint|-+)' }
}

Write-Hdr "The register"
if (Test-Path $reg) { Write-Ok "specs/nfr-register.md present" } else { Write-Bad "specs/nfr-register.md missing" }

if (Test-Path $reg) {
  $rows = Get-Rows $reg
  $r = 0; $full = 0; $own = 0; $vague = 0; $chk = 0
  foreach ($row in $rows) {
    $c = $row -split '\|'
    if ($c.Count -lt 7) { continue }
    $cells = @(); for ($i=1; $i -le 6; $i++) { $cells += $c[$i].Trim() }
    if ($cells[1] -ne '') { $r++ }
    if (($cells | Where-Object { $_ -eq '' }).Count -eq 0) { $full++ }
    if ($cells[3] -ne '') {
      if ($cells[3] -match '(?i)^(the business|business|it|team|ops|everyone)$') { $vague++ } else { $own++ }
    }
    if ($cells[4] -ne '') { $chk++ }
  }
  if ($r -ge 1) { Write-Ok "$r requirement(s) written" } else { Write-Bad "No requirements in the register" }
  if ($full -ge 1) { Write-Ok "$full line(s) fill all six columns" } else { Write-Warn "No line fills all six columns - an incomplete line is not ready" }
  if ($own -ge 1) { Write-Ok "$own threshold(s) have a named owner" } else { Write-Warn "No named owner anywhere - a threshold with no owner is folklore" }
  if ($vague -gt 0) { Write-Warn "$vague owner cell(s) say `"the business`" or similar - that is not a person" }
  if ($chk -ge 1) { Write-Ok "$chk line(s) say how they would be checked" } else { Write-Warn "Nothing says how it would be checked - an unverifiable requirement is a wish with a table row" }
  if ((Get-Content $reg -Raw) -match '(?i)\|[^|]*\b(fast|quick|secure|reliable|scalable|user.friendly|seamless)\b[^|]*\|') {
    Write-Warn "An adjective is doing the work of a threshold somewhere in the register"
  }
  if ($rows | Where-Object { $_ -match '(?i)^\|\s*operability' }) { Write-Ok "Operability has a line" }
  else { Write-Warn "No operability line - the family production cares about most" }
}

Write-Hdr "Constraints"
if (Test-Path $con) {
  Write-Ok "specs/constraints.md present"
  $ctext = Get-Content $con
  $started = $false; $plat = 0
  foreach ($l in $ctext) {
    if ($l -match '(?i)platform') { $started = $true }
    if ($started -and $l -match '^\|') {
      $c = $l -split '\|'
      if ($c.Count -ge 4) { $v = $c[2].Trim(); if ($v -ne '' -and $v -notmatch '^-+$' -and $v -ne 'What it means for us') { $plat++ } }
    }
  }
  if ($plat -ge 1) { Write-Ok "$plat platform constraint(s) have a consequence written against them" }
  else { Write-Warn "The platform table has no consequences filled in - the policy has not met your design yet" }
  if (($ctext -join "`n") -match '(?i)east us|canada central') { Write-Ok "The region constraint is recorded" }
  else { Write-Warn "The region constraint is not recorded" }
} else { Write-Bad "specs/constraints.md missing" }

Write-Hdr "Does the design fit the platform policy?"
$specFiles = Get-ChildItem (Join-Path $repo 'specs') -Recurse -File -ErrorAction SilentlyContinue |
             Where-Object { $_.Extension -in '.md','.yaml','.yml','.json' -and $_.Name -ne 'constraints.md' }
$specText = ($specFiles | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"
$hits = 0
foreach ($svc in 'azure sql','sql managed instance','postgres','postgresql','synapse','data factory','databricks','machine learning') {
  if ($specText -match [regex]::Escape($svc)) { Write-Warn "Your specs mention `"$svc`" - the lab policy denies it"; $hits++ }
}
foreach ($rgn in 'central india','centralindia','south india','west india') {
  if ($specText -match [regex]::Escape($rgn)) { Write-Warn "Your specs mention `"$rgn`" - that region is blocked"; $hits++ }
}
if ($hits -eq 0) { Write-Ok "Nothing in your specs names a denied service or a blocked region" }

Write-Hdr "Did it get shorter?"
if ((Test-Path (Join-Path $repo '.git')) -and (Test-Path $reg)) {
  $n = git -C $repo rev-list --count HEAD -- specs/nfr-register.md 2>$null
  if (-not $n) { $n = 0 }
  if ([int]$n -ge 2) {
    $now  = (Get-Rows $reg).Count
    $prev = (git -C $repo show HEAD~1:specs/nfr-register.md 2>$null |
             Where-Object { $_ -match '^\|' -and $_ -notmatch '(?i)^\|\s*(Family|-+)' }).Count
    if ($now -lt $prev) { Write-Ok "The register got shorter after the attack ($prev to $now lines)" }
    elseif ($now -eq $prev) { Write-Warn "The register is the same length - did anything survive being argued with?" }
    else { Write-Warn "The register grew ($prev to $now lines) - something has gone wrong" }
  } else { Write-Warn "Only $n commit(s) on the register - commit before the attack and after it" }
} else { Write-Warn "Not a git repository" }

Write-Summary
