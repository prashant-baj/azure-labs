<#
  MindSprint Junior SWAT Engineering Program 2026 - Labs
  check-integration.ps1  -  Session 6 integration decisions  (PowerShell)
  USAGE:  ./check-integration.ps1 -Path "C:\work\group-1"
  A bash twin (check-integration.sh) exists for macOS / Linux / WSL.
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
$dec  = Join-Path $repo 'specs\integration-decisions.md'
Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Session 6 - integration decisions"
Write-Host " $repo"
Write-Host "============================================================"
if (-not (Test-Path $repo)) { Write-Bad "Path not found: $repo"; exit 1 }

Write-Hdr "The file"
if (Test-Path $dec) { Write-Ok "specs/integration-decisions.md present" }
else { Write-Bad "specs/integration-decisions.md missing - copy templates/integration-decision.md into it"; Write-Summary }

$lines = Get-Content $dec
$text  = $lines -join "`n"

Write-Hdr "Decision records"
$records = ($lines | Where-Object { $_ -match '^## The seam' }).Count
if ($records -ge 2) { Write-Ok "$records seams have a decision record" }
elseif ($records -eq 1) { Write-Warn "Only one seam recorded - most designs have more than one edge" }
else { Write-Bad "No decision records found (expected '## The seam' per record)" }
if ($text -match '<our component>|<their system|<a person or a team|<the reason, not the preference>') {
  Write-Bad "Template placeholders are still in the file"
} else { Write-Ok "Template placeholders replaced" }

Write-Hdr "Ownership"
$owners = 0
for ($i=0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -match '^## Who owns the other side') {
    $j=$i+1; while ($j -lt $lines.Count -and $lines[$j].Trim() -eq '') { $j++ }
    if ($j -lt $lines.Count -and $lines[$j] -notmatch '^<' -and $lines[$j].Trim() -ne '') { $owners++ }
  }
}
if ($owners -ge 1) { Write-Ok "$owners seam(s) name an owner for the other side" }
else { Write-Warn "No owner named for any seam - that is a finding, not a detail" }
if ($lines | Where-Object { $_ -match '^\s*(IT|IT team|the business)\s*$' }) {
  Write-Warn "`"IT`" or `"the business`" is listed as an owner - neither is a person"
}

Write-Hdr "Options and rejections"
$rej = (Get-Section $lines '^## Rejected, and why' | Where-Object { $_ -match '^[-*]\s' -and $_ -notmatch '<Option>|<why it lost' }).Count
if ($rej -ge 2) { Write-Ok "$rej rejected options recorded with a reason" }
elseif ($rej -eq 1) { Write-Warn "Only one rejected option written down across all seams" }
else { Write-Bad "No rejected options - a record with no rejections is a preference, not a decision" }

Write-Hdr "Shape of each conversation"
$shapeLines = $lines | Where-Object { $_ -match '(?i)^\*\*Shape:\*\*\s*(request|event|file)' }
$shapes = ($shapeLines | ForEach-Object { ($_ -replace '(?i)^\*\*Shape:\*\*\s*','').Trim().ToLower() } | Sort-Object -Unique).Count
if ($shapeLines.Count -eq 0) { Write-Warn "No seam states its chosen shape - add '**Shape:** request | event | file'" }
elseif ($shapes -le 1 -and $records -ge 3) { Write-Warn "Every seam chose the same shape - fashion, or did each one genuinely need it?" }
else { Write-Ok "Shapes recorded across $($shapeLines.Count) seam(s)" }

Write-Hdr "How you find out it changed"
$chg = (Get-Section $lines '^## How we find out it changed' | Where-Object { $_.Trim() -ne '' -and $_ -notmatch '^<' }).Count
if ($chg -ge 1) { Write-Ok "$chg seam(s) say how a change would be noticed" }
else { Write-Warn "Nobody has said how you would find out the other side changed - the classic outage" }

Write-Hdr "The context diagram"
$dia = @(Get-ChildItem (Join-Path $repo 'specs\diagrams') -File -ErrorAction SilentlyContinue).Count
$mer = @(Get-ChildItem (Join-Path $repo 'specs') -Recurse -File -Filter *.md -ErrorAction SilentlyContinue |
         Where-Object { (Get-Content $_.FullName -Raw) -match '```mermaid' }).Count
if ($dia -ge 1) { Write-Ok "specs/diagrams holds $dia file(s)" }
elseif ($mer -ge 1) { Write-Ok "A diagram is embedded in specs/" }
else { Write-Warn "No context diagram found - a photograph of a whiteboard in specs/diagrams counts" }

Write-Hdr "Commit discipline"
if (Test-Path (Join-Path $repo '.git')) {
  $n = git -C $repo rev-list --count HEAD -- specs/integration-decisions.md 2>$null
  if (-not $n) { $n = 0 }
  if ([int]$n -ge 1) { Write-Ok "$n commit(s) touch the decisions file" }
  else { Write-Warn "The decisions file has not been committed yet" }
} else { Write-Warn "Not a git repository" }

Write-Summary
