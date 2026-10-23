# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-workshop-cd.ps1  -  Lab 09c: is the test deployment wired into the workshop
#                            repo, merged, recorded - and cleaned up?
#                            (Windows PowerShell 5.1 / PowerShell 7)
#
#  Checks files and records in git. It cannot see Azure or the GitLab pipeline - the
#  record in infra-test\DEPLOYED.md is your evidence, with the pipeline links in it.
#
#  USAGE
#    ./check-workshop-cd.ps1 [-Path "C:\work\case-a-nova-retail"]
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  Exit code is non-zero only if something required is missing - or a secret is committed.
#  A bash twin (check-workshop-cd.sh) exists for macOS / Linux / WSL.
# =============================================================================
param([string]$Path = ".")

$script:Pass = 0; $script:WarnN = 0; $script:Fail = 0
function Ok($m)   { Write-Host "  [ OK ] $m" -ForegroundColor Green; $script:Pass++ }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow; $script:WarnN++ }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:Fail++ }
function Hdr($m)  { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function ReadText($p) { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }

if (-not (Test-Path $Path)) { Write-Host "Path not found: $Path"; exit 1 }
$Repo = (Resolve-Path $Path).Path
$ci = Join-Path $Repo ".gitlab-ci.yml"; $infra = Join-Path $Repo "infra-test"; $rec = Join-Path $infra "DEPLOYED.md"

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - 09c - CD of a test resource - check"
Write-Host " $Repo"
Write-Host "============================================================"
if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository"; exit 1 }

# --- 1. Files ----------------------------------------------------------------------
Hdr "1 - The pipeline and the Terraform"
$haveFiles = $true
foreach ($f in @("ci/cd-test.yml", "infra-test/versions.tf", "infra-test/variables.tf", "infra-test/main.tf", "infra-test/outputs.tf")) {
  if (Test-Path (Join-Path $Repo $f)) { Ok $f } else { Bad "$f missing - run setup-workshop-cd"; $haveFiles = $false }
}
$vt = Join-Path $infra "versions.tf"
if (Test-Path $vt) {
  if ((ReadText $vt) -match 'backend\s+"azurerm"') { Ok "State kept in Azure (backend azurerm), not on a laptop" }
  else { Warn "No backend `"azurerm`" in infra-test/versions.tf - the pipeline cannot keep state between runs" }
}
$leak = @(git -C $Repo grep -nIE '(client_secret|ARM_CLIENT_SECRET|AZURE_CLIENT_SECRET)[[:space:]]*[:=][[:space:]]*["'']?[A-Za-z0-9~._-]{20,}|glpat-[A-Za-z0-9_-]{20,}' -- . ':!*.md' 2>$null | Select-Object -First 3)
if ($leak.Count -eq 0) { Ok "No Azure secrets or tokens committed" }
else { Bad "A secret looks committed - remove it, and tell your facilitator so it is rotated:"; $leak | ForEach-Object { Write-Host "         $_" } }
$state = @(git -C $Repo ls-files | Where-Object { $_ -match '(^|/)(\.terraform/|[^/]*\.tfstate|[^/]*\.tfplan$)' } | Select-Object -First 3)
if ($state.Count -eq 0) { Ok "No Terraform state, plans or .terraform/ in git" }
else { Bad "Terraform state or plans are committed (they can hold secrets): $($state -join ', ')" }

# --- 2. Pipeline -------------------------------------------------------------------
Hdr "2 - The pipeline includes it"
$included = $false
if (-not (Test-Path $ci)) { Bad "No .gitlab-ci.yml" }
else {
  $t = ReadText $ci
  if ($t -match 'ci/cd-test\.yml') { Ok "ci/cd-test.yml included in .gitlab-ci.yml"; $included = $true }
  else { Bad "ci/cd-test.yml not included - add  - local: ci/cd-test.yml  to include:" }
  if ($t -match '(?m)^stages:') {
    $st = @()
    if ($t -match '(?m)^stages:[ \t]*\[([^\]]*)\]') { $st = @($Matches[1] -split ',' | ForEach-Object { $_.Trim() }) }
    else {
      $in = $false
      foreach ($l in ($t -split "\r?\n")) {
        if ($l -match '^stages:') { $in = $true; continue }
        if ($in) { if ($l -match '^\s*-\s*([A-Za-z0-9_.-]+)') { $st += $Matches[1] } elseif ($l.Trim() -and -not $l.Trim().StartsWith('#')) { break } }
      }
    }
    foreach ($s in @('test', 'deploy')) {
      if ($st -contains $s) { Ok "stage $s exists" } else { Bad "stage $s missing from stages: - the pipeline will not even start" }
    }
  } else { Ok "No stages: list - the defaults include test and deploy" }
  if ($t -match '(?m)^(test|unit|pytest|lint|build)[A-Za-z0-9:_-]*:|(?m)^\s+stage:\s*(build|check|test)\s*$') { Ok "There are lint/test jobs - the deploy waits for them" }
  else { Warn "No test job besides the Terraform check - the deploy only waits for what is there" }
}
if ((Get-Command terraform -ErrorAction SilentlyContinue) -and (Test-Path $infra)) {
  Push-Location $infra; terraform fmt -check -recursive *> $null; $fmt = $LASTEXITCODE; Pop-Location
  if ($fmt -eq 0) { Ok "terraform fmt clean" } else { Warn "terraform fmt would change files - cdtest:validate will fail: run  terraform fmt -recursive  in infra-test\" }
}

# --- 3. Merged and deployed ----------------------------------------------------------
Hdr "3 - Merged, deployed, recorded"
$def = (git -C $Repo symbolic-ref --short refs/remotes/origin/HEAD 2>$null)
$def = if ($def) { ($def -replace '^origin/', '').Trim() } else { 'main' }
$mainRef = $null
foreach ($r in @("refs/remotes/origin/$def", "refs/heads/$def")) {
  git -C $Repo rev-parse -q --verify $r 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { $mainRef = $r; break }
}
$onMain = $false
if ($mainRef) { git -C $Repo cat-file -e "${mainRef}:ci/cd-test.yml" 2>$null; if ($LASTEXITCODE -eq 0) { $onMain = $true } }
if ($onMain) {
  Ok "On $def - merged, so main's pipeline deploys"
  $added = @(git -C $Repo log --format=%H --diff-filter=A $mainRef -- ci/cd-test.yml 2>$null) | Select-Object -Last 1
  $firstParent = @(git -C $Repo rev-list --first-parent $mainRef 2>$null)
  if ($added -and ($firstParent -contains $added)) { Warn "ci/cd-test.yml was committed straight onto $def, not merged from a branch - was the merge request skipped?" }
  else { Ok "Arrived by merge request" }
} else { Warn "Not on $def yet - push the branch and merge the merge request" }

$pipe = $false; $site = $false; $destroyed = $false; $second = $false
if (Test-Path $rec) {
  $r = [regex]::Replace((ReadText $rec), '<!--.*?-->', '')
  if ($r -match 'Pipeline \(first deploy\).*https?://[^ |]+/-/pipelines/[0-9]+') { $pipe = $true; Ok "First deploy recorded with its pipeline link" }
  else { Warn "DEPLOYED.md: no pipeline link for the first deploy yet" }
  if ($r -match 'https://[a-z0-9]+\.z[0-9]+\.web\.core\.windows\.net') { $site = $true; Ok "Site URL recorded" }
  else { Warn "DEPLOYED.md: no site URL (https://st....web.core.windows.net) yet" }
  if ($r -match 'Pipeline \(second deploy\).*https?://[^ |]+/-/pipelines/[0-9]+') { $second = $true; Ok "Second deploy recorded - a change rolled out by merge" }
  else { Warn "DEPLOYED.md: no second deploy yet - change 'message' in a merge request and record that pipeline" }
  if ($r -match '(?i)Destroyed[^|]*\|\s*(yes|auto)') { $destroyed = $true; Ok "Destroyed - the test resource is cleaned up" }
  else { Warn "DEPLOYED.md: not marked destroyed - run cdtest:destroy (or let auto-stop do it) and record it" }
  $learn = ($r -split 'What we learned', 2)
  if ($learn.Count -eq 2 -and @($learn[1] -split "\r?\n" | Where-Object { $_ -match '[A-Za-z]{3,}' }).Count -ge 1) { Ok "What we learned - written" }
  else { Warn "DEPLOYED.md: 'What we learned' is empty" }
} else { Warn "No infra-test/DEPLOYED.md - the record of your deployment" }

Hdr "Ready to point it at infra/?"
$script:Miss = 0
function Bar($yes, $m) { if ($yes) { Write-Host "  [ HAVE ] $m" -ForegroundColor Green } else { Write-Host "  [ NEED ] $m" -ForegroundColor Red; $script:Miss++ } }
Bar ($haveFiles -and $included) "Pipeline and Terraform in the repo, included"
Bar $onMain "Merged to main through a merge request"
Bar ($pipe -and $site) "Deployed by main's pipeline - recorded in DEPLOYED.md"
Bar $second "A change rolled out by a second merge"
Bar $destroyed "Test resource destroyed"
Bar (($leak.Count -eq 0) -and ($state.Count -eq 0)) "No secrets or state in git"
Write-Host ""
if ($script:Miss -eq 0) { Write-Host "  READY - the path works. Next: the same pipeline, pointed at your own infra/." -ForegroundColor Green }
else { Write-Host "  NOT YET - $($script:Miss) item(s) above." -ForegroundColor Yellow }

Write-Host ""
Write-Host "============================================================"
Write-Host " ok: $($script:Pass)   warnings: $($script:WarnN)   failed: $($script:Fail)"
Write-Host "============================================================"
if ($script:Fail -gt 0) { Write-Host " Something required is missing. Fix the [FAIL] lines and run again."; exit 1 }
if ($script:WarnN -gt 0) { Write-Host " Nothing is broken. Work through the warnings - they are the rest of the lab." }
exit 0
