<#
=============================================================================
  MindSprint Junior SWAT Engineering Program 2026 - Labs
  handin.ps1  -  Package a case repository for hand-in  (Windows PowerShell)

  For groups who cannot push to a remote yet. Produces ONE file containing the
  full repository AND its commit history, which the facilitator can restore.
  Use this only until hosting is sorted - a remote is better in every way.

  USAGE
    ./handin.ps1 -Path "C:\work\group-1" -Out "$HOME\Desktop"

  A bash twin (handin.sh) exists for macOS / Linux / WSL.
=============================================================================
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Path,
  [string]$Out = "."
)

function Write-Ok   { param($m) Write-Host "  [ OK ] $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Write-Bad  { param($m) Write-Host "  [FAIL] $m" -ForegroundColor Red }
function Write-Hdr  { param($m) Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - package case repository for hand-in"
Write-Host "============================================================"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Bad "Git is not installed."; exit 1 }
if (-not (Test-Path (Join-Path $Path '.git'))) { Write-Bad "$Path is not a git repository."; exit 1 }

$name  = Split-Path -Leaf (Resolve-Path $Path)
$stamp = Get-Date -Format 'yyyyMMdd'
$file  = Join-Path $Out "$name-$stamp.bundle"

Write-Hdr "Checking the repository"
$dirty = git -C $Path status --porcelain
if ($dirty) {
  Write-Warn "Uncommitted changes - these will NOT be included:"
  $dirty | ForEach-Object { Write-Host "        $_" }
  Write-Host "        Commit them first, then run this again."
} else {
  Write-Ok "Working tree is clean"
}
$commits = git -C $Path rev-list --count HEAD 2>$null
if (-not $commits) { $commits = 0 }
Write-Ok "$commits commits will be included"

Write-Hdr "Packaging"
New-Item -ItemType Directory -Path $Out -Force | Out-Null
git -C $Path bundle create $file --all | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Bad "Bundle failed."; exit 1 }
Write-Ok "Created $file"

git -C $Path bundle verify $file | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Bad "Bundle did not verify - do not hand this in."; exit 1 }
Write-Ok "Bundle verified"

$size = "{0:N0} KB" -f ((Get-Item $file).Length / 1KB)
Write-Ok "Size $size"

Write-Hdr "Hand it in"
@"
  Send this one file to the facilitator by whatever your team already uses.
  It carries every commit, so the difference between version one and version
  two is still reviewable.

  To restore it later, anywhere:
     git clone $(Split-Path -Leaf $file) $name

  When hosting is sorted, stop using this:
     git remote add origin <url> ; git push -u origin main
"@ | Write-Host
Write-Host ""
