<#
=============================================================================
  MindSprint Junior SWAT Engineering Program 2026 - Labs
  new-case-repo.ps1  -  Create a group's case repository  (Windows PowerShell)

  Copies the Session 5 template into a new folder, initialises git and makes
  the first commit. Run once per GROUP, not per person.

  USAGE
    ./new-case-repo.ps1 -Group group-1 -Path "C:\work"

  If scripts are blocked:
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

  A bash twin (new-case-repo.sh) exists for macOS / Linux / WSL.
=============================================================================
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Group,
  [string]$Path = "."
)

$ErrorActionPreference = 'Stop'

function Write-Ok   { param($m) Write-Host "  [ OK ] $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Write-Bad  { param($m) Write-Host "  [FAIL] $m" -ForegroundColor Red }
function Write-Hdr  { param($m) Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Session 5 - create case repository"
Write-Host "============================================================"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$template  = Join-Path $scriptDir 'template'
$dest      = Join-Path $Path $Group

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Bad "Git is not installed. Run 01-prereqs-check first."
  exit 1
}
if (-not (Test-Path $template)) {
  Write-Bad "Template folder not found next to this script."
  exit 1
}
if (Test-Path $dest) {
  Write-Bad "$dest already exists. Choose another name or remove it first."
  exit 1
}

Write-Hdr "Creating $dest"
New-Item -ItemType Directory -Path $Path -Force | Out-Null
Copy-Item -Recurse -Path $template -Destination $dest
Write-Ok "Template copied"

Copy-Item (Join-Path $dest 'templates\solution-definition.md') (Join-Path $dest 'specs\solution-definition.md')
Write-Ok "specs/solution-definition.md created from the template"

Write-Hdr "Initialising git"
Push-Location $dest
try {
  git init -q -b main 2>$null
  if ($LASTEXITCODE -ne 0) { git init -q }
  git add -A
  git -c user.name="$Group" -c user.email="$Group@example.invalid" commit -q -m "chore: case repository created from Session 5 lab template"
  if ($LASTEXITCODE -eq 0) { Write-Ok "First commit made" } else { Write-Warn "First commit did not complete - check your git config" }
}
finally { Pop-Location }

Write-Hdr "Next"
@"
  1. cd $dest
  2. Paste your four Module 1 artefacts into docs\
  3. Fill the glossary table in CLAUDE.md - the client's words
  4. Write specs\solution-definition.md as a group, BY HAND
  5. Commit it:  git commit -am "spec: solution definition v1"
  6. Only then run the prompts in prompts\
  7. Check yourself:  ./check-spec-repo.ps1 -Path "$dest"

  Add your remote when you have one:
     git remote add origin <url> ; git push -u origin main
"@ | Write-Host
Write-Host ""
