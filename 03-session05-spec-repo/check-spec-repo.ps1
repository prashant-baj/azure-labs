<#
=============================================================================
  MindSprint Junior SWAT Engineering Program 2026 - Labs
  check-spec-repo.ps1  -  Session 5 solution definition check  (PowerShell)

  Checks that a group's case repository is in a state the next three sessions
  can build on. It checks structure and discipline, never the quality of your
  thinking - that is what the debrief is for.

  USAGE
    ./check-spec-repo.ps1 -Path "C:\work\group-1"

  Exit code is non-zero if any REQUIRED check fails.
  A bash twin (check-spec-repo.sh) exists for macOS / Linux / WSL.
=============================================================================
#>

[CmdletBinding()]
param([string]$Path = ".")

$script:Pass = 0; $script:Warn = 0; $script:Fail = 0
function Write-Ok   { param($m) Write-Host "  [ OK ] $m" -ForegroundColor Green;  $script:Pass++ }
function Write-Warn { param($m) Write-Host "  [WARN] $m" -ForegroundColor Yellow; $script:Warn++ }
function Write-Bad  { param($m) Write-Host "  [FAIL] $m" -ForegroundColor Red;    $script:Fail++ }
function Write-Hdr  { param($m) Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }

function Get-Section {
  param([string[]]$Lines, [string]$HeadingPattern)
  $out = @(); $in = $false
  foreach ($l in $Lines) {
    if ($l -match $HeadingPattern) { $in = $true; continue }
    if ($in -and $l -match '^##\s') { break }
    if ($in) { $out += $l }
  }
  return $out
}

$repo = $Path
$spec = Join-Path $repo 'specs\solution-definition.md'

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Session 5 - solution definition check"
Write-Host " $repo"
Write-Host "============================================================"

if (-not (Test-Path $repo)) { Write-Bad "Path not found: $repo"; exit 1 }

Write-Hdr "Repository structure"
foreach ($d in 'docs','specs','templates','prompts') {
  if (Test-Path (Join-Path $repo $d)) { Write-Ok "$d/ present" } else { Write-Bad "$d/ missing" }
}
if (Test-Path (Join-Path $repo 'CLAUDE.md')) { Write-Ok "CLAUDE.md present" } else { Write-Bad "CLAUDE.md missing" }
if (Test-Path $spec) { Write-Ok "specs/solution-definition.md present" } else { Write-Bad "specs/solution-definition.md missing" }
if (Test-Path (Join-Path $repo '.git')) { Write-Ok "It is a git repository" } else { Write-Bad "Not a git repository - run new-case-repo first" }

$docFiles = @()
if (Test-Path (Join-Path $repo 'docs')) {
  $docFiles = Get-ChildItem -Path (Join-Path $repo 'docs') -Recurse -File -ErrorAction SilentlyContinue |
              Where-Object { $_.Extension -in '.md','.txt','.docx','.pdf' -and $_.Name -ne 'README.md' }
}
if ($docFiles.Count -ge 3) { Write-Ok "docs/ holds $($docFiles.Count) files" }
elseif ($docFiles.Count -gt 0) { Write-Warn "docs/ holds only $($docFiles.Count) file(s) - four Module 1 artefacts were expected" }
else { Write-Warn "docs/ is empty - paste in your Module 1 artefacts" }

if (-not (Test-Path $spec)) {
  Write-Host ""; Write-Host "Cannot check the definition itself. Stopping."
  exit 1
}

$lines = Get-Content $spec
$text  = $lines -join "`n"

Write-Hdr "Solution definition"

if ($text -match '<case name>|<One paragraph|<Three to five|<names>|<date>') {
  Write-Bad "Template placeholders are still in the file"
} else { Write-Ok "Template placeholders replaced" }

$objLines = Get-Section $lines '^##\s*2\.\s*Objectives'
$obj = ($objLines | Where-Object { $_ -match '^\d+\.\s+\S' }).Count
if ($obj -eq 0) { Write-Bad "No objectives found in section 2" }
elseif ($obj -gt 5) { Write-Warn "$obj objectives - more than five is usually a feature list" }
else { Write-Ok "$obj objectives" }

$scopeRows = Get-Section $lines '^##\s*3\.\s*Scope' | Where-Object { $_ -match '^\|' -and $_ -notmatch '^\|\s*(In scope|-+)' }
$notNow = 0; $outOwner = 0
foreach ($r in $scopeRows) {
  $c = $r -split '\|'
  if ($c.Count -ge 4) {
    if ($c[2].Trim() -ne '') { $outOwner++ }
    if ($c[3].Trim() -ne '') { $notNow++ }
  }
}
if ($notNow -ge 1) { Write-Ok "Something is in the `"Not now`" column" }
else { Write-Warn "`"Not now`" column is empty - the scope conversation has probably not happened yet" }
if ($outOwner -ge 1) { Write-Ok "Out-of-scope items listed" }
else { Write-Warn "Nothing marked out of scope - is everything really yours?" }

$stories = ($lines | Where-Object { $_ -match '^[-*]\s+As an?\s' -and $_ -notmatch '<role>|<what>|<why' }).Count
if ($stories -ge 1) { Write-Ok "$stories story/stories written" } else { Write-Bad "No stories found" }
if ($lines | Where-Object { $_ -match '(?i)^[-*]\s+As an?\s+(user|end user)[\s,]' }) {
  Write-Warn "A story uses `"as a user`" - name the actual role from your concern sheet"
}

$shall = ($lines | Where-Object { $_ -match '\bshall\b' }).Count
if ($shall -ge 2) { Write-Ok "$shall requirement statements in EARS form" }
elseif ($shall -eq 1) { Write-Warn "Only one EARS statement found" }
else { Write-Bad "No acceptance criteria in EARS form (When ..., the system shall ...)" }

if ($text -match '(?i)user.friendly|seamless|as per discussion|industry standard') {
  Write-Warn "A phrase that cannot fail is still in the file (user friendly / seamless / as per discussion)"
}

$assumeRows = Get-Section $lines '^##\s*7\.\s*Assumptions' | Where-Object { $_ -match '^\|' }
$assume = 0
foreach ($r in $assumeRows) {
  $c = $r -split '\|'
  if ($c.Count -ge 3) {
    $v = $c[1].Trim()
    if ($v -ne '' -and $v -notmatch '^-+$' -and $v -ne 'We are assuming') { $assume++ }
  }
}
if ($assume -ge 1) { Write-Ok "$assume assumption(s) recorded" }
else { Write-Warn "Assumptions and open questions is empty - a tidy document is usually a dishonest one" }

Write-Hdr "Glossary"
$gloss = 0
$claude = Join-Path $repo 'CLAUDE.md'
if (Test-Path $claude) {
  $gl = Get-Section (Get-Content $claude) '^##\s*Glossary' | Where-Object { $_ -match '^\|' }
  foreach ($r in $gl) {
    $c = $r -split '\|'
    if ($c.Count -ge 4) {
      $v = $c[1].Trim()
      if ($v -ne '' -and $v -notmatch '^-+$' -and $v -ne 'Term') { $gloss++ }
    }
  }
}
if ($gloss -ge 1) { Write-Ok "$gloss term(s) in the glossary" }
else { Write-Warn "Glossary in CLAUDE.md is empty - the assistant will use your words instead of the client's" }

Write-Hdr "Commit discipline"
if (Test-Path (Join-Path $repo '.git')) {
  $n = (git -C $repo rev-list --count HEAD -- specs/solution-definition.md 2>$null)
  if (-not $n) { $n = 0 }
  $n = [int]$n
  if ($n -ge 2) { Write-Ok "$n commits touch the solution definition (v1 before review, v2 after)" }
  elseif ($n -eq 1) { Write-Warn "Only one commit touches the definition - was v1 committed before the assistant saw it?" }
  else { Write-Warn "The solution definition has not been committed yet" }
  $remotes = (git -C $repo remote 2>$null)
  if ($remotes) { Write-Ok "A remote is configured" } else { Write-Warn "No git remote - add one and push before you leave" }
}

Write-Host ""
Write-Host "============================================================"
Write-Host " ok: $script:Pass   warnings: $script:Warn   failed: $script:Fail"
Write-Host "============================================================"
if ($script:Fail -gt 0) {
  Write-Host " Something required is missing. Fix the [FAIL] lines and run again."
  exit 1
}
if ($script:Warn -gt 0) {
  Write-Host " Nothing is broken. Read the warnings and decide - they are judgement calls,"
  Write-Host " and at the debrief you will be asked about them."
}
exit 0
