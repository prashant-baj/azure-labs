# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  setup-workshop-cd.ps1  -  Lab 09c: continuous deployment of a TEST resource from
#                            your workshop project to Azure
#                            (Windows PowerShell 5.1 / PowerShell 7)
#
#  What it does, once per group (a Maintainer runs it):
#    1. Adds ci\cd-test.yml (the pipeline) and infra-test\ (the Terraform)
#    2. Includes ci/cd-test.yml in .gitlab-ci.yml and makes sure the stages test and deploy exist
#    3. Keeps Terraform's local files out of git (.gitignore)
#    4. Checks the Terraform (fmt + validate) if terraform is installed
#    5. Commits all of it on a branch cd-test - main is protected, so it goes in by merge request
#
#  It never deletes anything, and never overwrites a file you have written.
#
#  USAGE
#    ./setup-workshop-cd.ps1 -Path "C:\work\case-a-nova-retail"
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  A bash twin (setup-workshop-cd.sh) exists for macOS / Linux / WSL.
# =============================================================================
param(
  [Parameter(Mandatory=$true)][string]$Path
)

function Ok($m)   { Write-Host "  [ OK ] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red }
function Hdr($m)  { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
$Utf8 = New-Object System.Text.UTF8Encoding $false
function ReadText($p)  { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }
function WriteText($p, $t) { [System.IO.File]::WriteAllText($p, $t, $Utf8) }

$Here = $PSScriptRoot
$Branch = 'cd-test'
if (-not (Test-Path $Path)) { Bad "Path not found: $Path"; exit 1 }
$Repo = (Resolve-Path $Path).Path
$ci = Join-Path $Repo ".gitlab-ci.yml"

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - 09c - CD of a test resource to Azure"
Write-Host " $Repo"
Write-Host "============================================================"

Hdr "Before we start"
if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository."; exit 1 }
if (-not (Test-Path (Join-Path $Repo "constitution.md"))) { Warn "No constitution.md - is this your workshop repo? Carrying on" }
if (git -C $Repo status --porcelain) { Bad "You have uncommitted changes. Commit or stash them first, so this step is one clean commit."; exit 1 }
$cur = (git -C $Repo rev-parse --abbrev-ref HEAD).Trim()
$def = (git -C $Repo symbolic-ref --short refs/remotes/origin/HEAD 2>$null)
$def = if ($def) { ($def -replace '^origin/', '').Trim() } else { 'main' }
if ($cur -eq $def) {
  git -C $Repo pull --ff-only --quiet 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok "$def is up to date with GitLab" } else { Warn "Could not pull $def - carrying on with what you have" }
  git -C $Repo rev-parse -q --verify "refs/heads/$Branch" 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { git -C $Repo switch --quiet $Branch 2>$null; Warn "Branch $Branch already existed - switched to it" }
  else { git -C $Repo switch --quiet -c $Branch 2>$null; Ok "Created branch $Branch from $def" }
  $cur = $Branch
} else { Ok "Working on branch $cur" }

function Add-File($src, $rel) {   # never overwrites
  $dst = Join-Path $Repo $rel
  if (Test-Path $dst) { Ok "$rel already exists - left alone"; return }
  New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
  Copy-Item $src $dst; Ok "$rel added"
}

Hdr "1 - The pipeline and the Terraform"
Add-File (Join-Path $Here "ci\cd-test.yml") "ci\cd-test.yml"
foreach ($f in @("versions.tf", "variables.tf", "main.tf", "outputs.tf", "site\index.html.tftpl")) {
  Add-File (Join-Path $Here "infra-test\$f") "infra-test\$f"
}
Add-File (Join-Path $Here "templates\DEPLOYED.md") "infra-test\DEPLOYED.md"

Hdr "2 - .gitlab-ci.yml"
if (-not (Test-Path $ci)) {
  WriteText $ci "# The group pipeline.`nstages: [test, deploy]`n`ninclude:`n  - local: ci/cd-test.yml`n"
  Ok ".gitlab-ci.yml created with the test deployment included"
  Warn "You had no pipeline at all - add your lint and test jobs too (08-session10-excellence\ci\)"
} else {
  $t = ReadText $ci
  $nl = if ($t -match "`r`n") { "`r`n" } else { "`n" }
  if ($t -match 'ci/cd-test\.yml') { Ok "ci/cd-test.yml is already included" }
  elseif ($t -match '(?m)^include:[ \t]*\[(.*)\][ \t]*\r?$') {                       # include: [{ local: a.yml }]
    $t = [regex]::Replace($t, '(?m)^include:[ \t]*\[(.*)\][ \t]*(?=\r?$)', 'include: [$1, { local: ci/cd-test.yml }]', 1)
    Ok "ci/cd-test.yml added to your include: list"
  }
  elseif ($t -match '(?m)^include:[ \t]*\r?$') {                                    # include:\n  - local: a.yml
    $t = ([regex]'(?m)^include:[ \t]*(?=\r?$)').Replace($t, "include:$nl  - local: ci/cd-test.yml", 1)
    Ok "ci/cd-test.yml added to your include: list"
  }
  elseif ($t -match '(?m)^include:') { Warn "Your include: is written in a form this script does not edit. Add this yourself:   - local: ci/cd-test.yml" }
  else { $t = $t.TrimEnd() + "$nl$nl" + "include:$nl  - local: ci/cd-test.yml$nl"; Ok "ci/cd-test.yml included" }

  if ($t -notmatch '(?m)^stages:') { Ok "No stages: list - GitLab's default (build, test, deploy) already has test and deploy" }
  elseif ($t -match '(?m)^stages:[ \t]*\[([^\]]*)\]') {                              # stages: [check, test]
    $items = @($Matches[1] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $before = $items.Count
    foreach ($s in @('test', 'deploy')) { if ($items -notcontains $s) { $items += $s } }
    if ($items.Count -ne $before) {
      $t = [regex]::Replace($t, '(?m)^stages:[ \t]*\[[^\]]*\]', ('stages: [' + ($items -join ', ') + ']'), 1)
      Ok "stages: now  [$($items -join ', ')]"
    } else { Ok "stages: already has test and deploy" }
  } else {                                                                            # stages:\n  - check\n  - test
    $lines = [Collections.Generic.List[string]]($t -split "\r?\n")
    $start = -1; for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^stages:') { $start = $i; break } }
    $end = $start; $have = @()
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -match '^\s*-\s*([A-Za-z0-9_.-]+)') { $have += $Matches[1]; $end = $i } else { break }
    }
    foreach ($s in @('test', 'deploy')) {
      if ($have -notcontains $s) { $end++; $lines.Insert($end, "  - $s"); $have += $s; Ok "stage $s added to stages:" }
    }
    $t = $lines -join $nl
  }
  WriteText $ci $t
}

Hdr "3 - .gitignore - Terraform's local files never go to git"
$gi = Join-Path $Repo ".gitignore"
$g = if (Test-Path $gi) { ReadText $gi } else { "" }
$have = @($g -split "\r?\n")
$add = @('.terraform/', '*.tfstate', '*.tfstate.*', '*.tfplan', '*.tfvars', 'cdtest.env') | Where-Object { $have -notcontains $_ }
if ($add) {
  if ($g -and -not $g.EndsWith("`n")) { $g += "`n" }
  WriteText $gi ($g + (($add -join "`n") + "`n")); $add | ForEach-Object { Ok "$_ added" }
}
Ok ".gitignore covers Terraform state, plans, tfvars and .terraform/"

Hdr "4 - Terraform check"
if (Get-Command terraform -ErrorAction SilentlyContinue) {
  Push-Location (Join-Path $Repo "infra-test")
  terraform fmt -check -recursive *> $null; $a = $LASTEXITCODE
  terraform init -backend=false -input=false *> $null
  terraform validate -no-color *> $null; $b = $LASTEXITCODE
  Pop-Location
  if ($a -eq 0 -and $b -eq 0) { Ok "terraform fmt and validate pass" } else { Warn "terraform fmt/validate reported something - run it in infra-test\ and read it" }
} else { Warn "terraform not installed here - fine, the pipeline job cdtest:validate does the same check" }

Hdr "5 - Commit"
git -C $Repo add ci/cd-test.yml infra-test .gitlab-ci.yml .gitignore
git -C $Repo diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Ok "Nothing new to commit" }
else {
  git -C $Repo commit --quiet -m "ci: deploy a test resource to Azure from main (lab 09c)"
  if ($LASTEXITCODE -eq 0) { Ok "Committed on $cur" } else { Bad "Commit failed - see the message above" }
}

Write-Host ""
Write-Host "============================================================"
Write-Host " Next - README step 3:"
Write-Host "   1. Read the diff:   git -C `"$Repo`" show --stat"
Write-Host "   2. Push and open the merge request in one go:"
Write-Host "        git -C `"$Repo`" push -u origin $cur -o merge_request.create -o merge_request.target=$def -o merge_request.title=`"CD test: deploy a test resource to Azure`""
Write-Host "   3. Branch pipeline: cdtest:validate must be green. Then review and merge as usual."
Write-Host "   4. On ${def}: watch cdtest:state -> plan -> apply -> verify. Open Operate > Environments > cd-test."
Write-Host "============================================================"
