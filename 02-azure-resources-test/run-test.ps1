<#
=============================================================================
  MindSprint Junior SWAT Engineering Program 2026 - Labs
  02-azure-resources-test / run-test.ps1   (Windows)

  Runs the whole serverless-stack test in the right order, and prepares this
  machine so it also works behind a company proxy that inspects HTTPS traffic.

  Start it with   run-test.cmd       (deploy and check)
                  destroy-test.cmd   (tear everything down)
  or, from a terminal in this folder:
                  Get-Content .\run-test.ps1 -Raw | Invoke-Expression

  Step 2 runs ..\tools\fix-company-proxy.ps1: for this run it uses your
  company proxy if Windows has one, and - only if your network inspects
  HTTPS - makes the Azure CLI, Git and npm trust what Windows already trusts.
  User-level only, nothing bypassed. Details and undo: ..\tools\README.md
=============================================================================
#>
# No param() block, so it also runs via Get-Content | Invoke-Expression on
# machines where PowerShell execution policy blocks .ps1 files.

function Invoke-ResourcesTest {
  $ErrorActionPreference = 'Continue'
  $mode = if ($Mode) { $Mode } else { 'apply' }

  function Hdr ($t) { Write-Host ''; Write-Host "==> $t" -ForegroundColor Cyan }
  function Ok  ($t) { Write-Host "  [ OK ] $t" -ForegroundColor Green }
  function Wrn ($t) { Write-Host "  [WARN] $t" -ForegroundColor Yellow }
  function Bad ($t) { Write-Host "  [FAIL] $t" -ForegroundColor Red }
  function Say ($t) { Write-Host "         $t" }

  if ($PSScriptRoot) { Set-Location $PSScriptRoot }
  if (-not (Test-Path '.\main.tf')) {
    Bad 'Run this from the 02-azure-resources-test folder (main.tf not found here).'
    return
  }

  Write-Host '============================================================'
  Write-Host " Junior SWAT Labs - 02 - Azure resources test ($mode)"
  Write-Host '============================================================'

  # ---- 1. Tools --------------------------------------------------------------
  Hdr '1. Tools'
  foreach ($t in 'az', 'terraform') {
    if (Get-Command $t -ErrorAction SilentlyContinue) { Ok "$t found" }
    else { Bad "$t not found - run 01-prereqs-check first"; return }
  }

  # ---- 2. Network and certificates ------------------------------------------
  # Shared with the other labs: ..\tools\fix-company-proxy.ps1. It uses your
  # company proxy for this run, and - only if your network inspects HTTPS -
  # makes the Azure CLI trust what Windows already trusts. See tools\README.md.
  Hdr '2. Network and certificates'
  $helper = Join-Path (Get-Location).Path '..\tools\fix-company-proxy.ps1'
  if (Test-Path $helper) {
    $ProxyFixNoRun = $true
    Get-Content -Raw $helper | Invoke-Expression
    $trusted = Invoke-CompanyProxyFix -Action 'auto' | Select-Object -Last 1
    if (-not $trusted) { return }
  } else {
    Wrn 'tools\fix-company-proxy.ps1 not found - skipping this step (download the whole repository, not one folder)'
  }

  # ---- 3. Sign in ------------------------------------------------------------
  Hdr '3. Azure sign-in'
  az group list -o none 2>$null
  if ($LASTEXITCODE -ne 0) {
    Say 'Signing you in - pick your lab account (loginId) when the sign-in window opens.'
    az login -o none
    if ($LASTEXITCODE -ne 0) {
      Wrn 'Browser sign-in did not complete - trying device-code sign-in instead'
      az login --use-device-code -o none
    }
    az group list -o none 2>$null
    if ($LASTEXITCODE -ne 0) {
      Bad 'Signed in, but the lab subscription is not reachable.'
      Say 'Check the vlabs panel shows "Start - Complete" (the lab resets every ~4 hours).'
      return
    }
  }
  $subId   = az account show --query id -o tsv
  $subName = az account show --query name -o tsv
  $env:ARM_SUBSCRIPTION_ID = $subId
  Ok "Using subscription $subName ($subId)"

  # ---- 4. Resource providers -------------------------------------------------
  Hdr '4. Resource providers'
  $rps = 'Microsoft.OperationalInsights', 'Microsoft.Insights', 'Microsoft.ContainerRegistry', 'Microsoft.App',
         'Microsoft.DocumentDB', 'Microsoft.ServiceBus', 'Microsoft.KeyVault', 'Microsoft.Storage'
  $pending = @()
  if ($mode -eq 'destroy') { $rps = @(); Ok 'Not needed for destroy - skipped' }
  foreach ($rp in $rps) {
    $state = az provider show -n $rp --query registrationState -o tsv 2>$null
    if ($state -eq 'Registered') { Ok "$rp" } else { az provider register -n $rp -o none 2>$null; $pending += $rp }
  }
  foreach ($rp in $pending) {
    Say "Waiting for $rp to register..."
    az provider register -n $rp --wait -o none
    if ($LASTEXITCODE -eq 0) { Ok "$rp registered" } else { Bad "$rp could not be registered"; return }
  }

  # ---- 5. Terraform ----------------------------------------------------------
  Hdr '5. Terraform'

  # State from an earlier lab session points at a subscription that no longer
  # exists (the lab resets every ~4 hours). Set it aside instead of fighting it.
  if (Test-Path '.\terraform.tfstate') {
    $raw  = Get-Content '.\terraform.tfstate' -Raw
    $subs = [regex]::Matches($raw, '/subscriptions/([0-9a-fA-F-]{36})') |
            ForEach-Object { $_.Groups[1].Value.ToLower() } | Sort-Object -Unique
    if ($subs | Where-Object { $_ -ne $subId.ToLower() }) {
      $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
      Rename-Item '.\terraform.tfstate' "terraform.tfstate.$stamp.old"
      if (Test-Path '.\terraform.tfstate.backup') { Rename-Item '.\terraform.tfstate.backup' "terraform.tfstate.backup.$stamp.old" }
      Ok 'Found state from an earlier lab session (that subscription is gone) - set it aside, starting fresh'
      if ($mode -eq 'destroy') { Say 'Nothing to destroy: the lab reset already removed those resources.'; return }
    }
  }

  terraform init -input=false
  if ($LASTEXITCODE -ne 0) { Bad 'terraform init failed - see the message above, and "Troubleshooting" in README.md'; return }

  if ($mode -eq 'destroy') {
    Say 'Terraform will list what it is about to delete. Type yes to confirm.'
    terraform destroy
    if ($LASTEXITCODE -eq 0) { Ok 'Everything this test created has been deleted' } else { Bad 'terraform destroy did not finish - run destroy-test.cmd again' }
    return
  }

  Say 'Read the plan - on a fresh run it says "Plan: 11 to add, 0 to change, 0 to destroy". Then type yes.'
  terraform apply
  if ($LASTEXITCODE -ne 0) { Bad 'terraform apply failed - see the error above, and ../lab-constraints.md for the usual causes'; return }

  # ---- 6. Check the app ------------------------------------------------------
  Hdr '6. Check the app responds'
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072 } catch {}
  $url = terraform output -raw app_url
  $up = $false
  for ($i = 1; $i -le 12 -and -not $up; $i++) {
    try {
      $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20
      if ($r.StatusCode -eq 200) { $up = $true }
    } catch {}
    if (-not $up) { Say "Waiting for the app to start ($i/12)..."; Start-Sleep -Seconds 10 }
  }
  if ($up) { Ok "App returned 200 at $url" } else { Bad "App did not respond at $url - check the Container App in the portal" }

  Write-Host ''
  Write-Host '============================================================'
  Write-Host ' Next: open the resource group in the Azure portal and compare it'
  Write-Host ' with images\expected-resources.png (README step 3b).'
  Write-Host ' When you are done: destroy-test.cmd  (or: terraform destroy)'
  Write-Host '============================================================'
}

Invoke-ResourcesTest
