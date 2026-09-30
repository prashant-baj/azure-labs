<#
  MindSprint Junior SWAT Engineering Program 2026 - Labs
  check-contracts.ps1  -  Session 7 contracts and ADRs  (PowerShell)
  USAGE:  ./check-contracts.ps1 -Path "C:\work\group-1"
  A bash twin (check-contracts.sh) exists for macOS / Linux / WSL.
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
$cdir = Join-Path $repo 'specs\contracts'
$adir = Join-Path $repo 'specs\adr'
Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Session 7 - contracts and decision records"
Write-Host " $repo"
Write-Host "============================================================"
if (-not (Test-Path $repo)) { Write-Bad "Path not found: $repo"; exit 1 }

Write-Hdr "Contracts"
$cfiles = @()
if (Test-Path $cdir) {
  $cfiles = Get-ChildItem $cdir -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in '.md','.yaml','.yml','.json' }
  if ($cfiles.Count -ge 1) { Write-Ok "$($cfiles.Count) contract file(s) in specs/contracts" }
  else { Write-Bad "specs/contracts is empty" }
} else { Write-Bad "specs/contracts missing" }

if ($cfiles.Count -ge 1) {
  $all = ($cfiles | ForEach-Object { Get-Content $_.FullName }) 
  $allText = $all -join "`n"

  $errRows = (Get-Section $all '^##\s*2\.\s*Errors' | Where-Object { $_ -match '^\|' } | ForEach-Object {
                $c = $_ -split '\|'; if ($c.Count -ge 3) { $v=$c[1].Trim(); if ($v -ne '' -and $v -notmatch '^-+$' -and $v -ne 'What went wrong') { $_ } } }).Count
  $errCodes = ($all | Where-Object { $_ -match '\b(4\d{2}|5\d{2})\b' }).Count
  if ($errRows -ge 2 -or $errCodes -ge 2) { Write-Ok "Error cases described" }
  elseif ($errRows -eq 1 -or $errCodes -eq 1) { Write-Warn "Only one error case - a draft always gives you exactly one" }
  else { Write-Bad "No error cases - this is the first thing a draft gets wrong" }

  foreach ($pair in @(@('Timing','timing'),@('Size','size'),@('Duplicates','duplicate'),@('Changing','version'))) {
    $h = $pair[0]; $w = $pair[1]
    $hit = (Get-Section $all "^##\s*\d*\.?\s*$h" | Where-Object { $_.Trim() -ne '' -and $_ -notmatch '^<|^-\s*$' }).Count
    $alt = ($all | Where-Object { $_ -match "(?i)$w" }).Count
    if ($hit -ge 1) { Write-Ok "$h section filled in" }
    elseif ($alt -ge 1) { Write-Warn "$h is mentioned but the section is empty" }
    else { Write-Warn "$h not covered - drafts leave this out unless asked" }
  }

  if ($allText -match '(?i)inferred|assumed') { Write-Ok "The draft marked what it inferred, and the marks are still visible" }
  else { Write-Warn "Nothing is marked as inferred - either it was asked, or the marks were deleted with the evidence" }
}

Write-Hdr "Architecture decision records"
if (Test-Path $adir) {
  $adrs = Get-ChildItem $adir -File -Filter *.md -ErrorAction SilentlyContinue
  if ($adrs.Count -ge 2) { Write-Ok "$($adrs.Count) ADRs written" }
  elseif ($adrs.Count -eq 1) { Write-Warn "Only one ADR - two were asked for" }
  else { Write-Bad "specs/adr is empty" }
  foreach ($f in $adrs) {
    $l = Get-Content $f.FullName
    $miss = @()
    foreach ($h in 'Context','Decision','Alternatives','Consequences') {
      if (-not ($l | Where-Object { $_ -match "(?i)^##\s*$h" })) { $miss += $h }
    }
    if ($miss.Count -gt 0) { Write-Warn "$($f.Name) is missing: $($miss -join ' ')" }
    else { Write-Ok "$($f.Name) has all four sections" }
    $alts = (Get-Section $l '^##\s*Alternatives' | Where-Object { $_ -match '^[-*]\s' -and $_ -notmatch '<Option>|<why it lost' }).Count
    if ($alts -lt 2) { Write-Warn "$($f.Name) lists fewer than two alternatives" }
    $badl = (Get-Section $l '^##\s*Consequences' | Where-Object { $_ -match '(?i)^\*\*Bad:\*\*' -and ($_ -replace '(?i)^\*\*Bad:\*\*','').Trim() -ne '' -and ($_ -replace '(?i)^\*\*Bad:\*\*','').Trim() -notmatch '^<' }).Count
    if ($badl -lt 1) { Write-Warn "$($f.Name) has no bad consequences - that is marketing, not a record" }
  }
} else { Write-Bad "specs/adr missing" }

Write-Hdr "Commit discipline"
if (Test-Path (Join-Path $repo '.git')) {
  $n = git -C $repo rev-list --count HEAD -- specs/contracts 2>$null
  if (-not $n) { $n = 0 }
  if ([int]$n -ge 2) { Write-Ok "$n commits touch the contracts - the draft was corrected" }
  elseif ([int]$n -eq 1) { Write-Warn "One commit only - was the draft accepted unchanged?" }
  else { Write-Warn "Contracts not committed yet" }
} else { Write-Warn "Not a git repository" }

Write-Summary
