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

  What it changes on your machine - all user-level, nothing needs admin:
    * If (and only if) your network inspects HTTPS, it writes
      %USERPROFILE%\.azure\ca-bundle.pem - the certificates Windows already
      trusts - and sets REQUESTS_CA_BUNDLE for your user so the Azure CLI
      trusts the same things Windows does. Nothing is bypassed.
    * For this run only, it tells az and terraform to use your company proxy
      if Windows has one configured.
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

  # ---- 2. Company proxy (this run only) --------------------------------------
  Hdr '2. Network'
  $target = [Uri]'https://management.azure.com'
  if ($env:HTTPS_PROXY) {
    Ok "Using the proxy already set in HTTPS_PROXY ($env:HTTPS_PROXY)"
  } else {
    try {
      $p = [Net.WebRequest]::GetSystemWebProxy().GetProxy($target)
      if ($p -and $p.Host -ne $target.Host) {
        $env:HTTPS_PROXY = $p.AbsoluteUri.TrimEnd('/')
        $env:HTTP_PROXY  = $env:HTTPS_PROXY
        $env:NO_PROXY    = 'localhost,127.0.0.1'
        Ok "Windows uses a proxy ($env:HTTPS_PROXY) - az and terraform will use it for this run"
      } else {
        Ok 'No explicit proxy configured'
      }
    } catch { Wrn 'Could not read the Windows proxy settings - continuing without them' }
  }

  # ---- 3. Certificates -------------------------------------------------------
  Hdr '3. Certificates'
  $py = $null
  $verLine = (az --version 2>$null) | Where-Object { $_ -match "^Python location '(.+)'" } | Select-Object -First 1
  if ($verLine -and ($verLine -match "^Python location '(.+)'")) { $py = $Matches[1] }
  if (-not $py) {
    $py = (Get-ChildItem 'C:\Program Files*\Microsoft SDKs\Azure\CLI2\python.exe' -ErrorAction SilentlyContinue |
           Select-Object -First 1).FullName
  }

  $probe = "import requests; requests.get('https://management.azure.com', timeout=20)"
  if (-not $py) {
    Wrn 'Could not locate the Azure CLI''s Python - skipping the certificate check'
  } else {
    $out = & $py -c $probe 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
      Ok 'The Azure CLI can reach Azure securely'
    } elseif ($out -match 'CERTIFICATE_VERIFY_FAILED') {
      Say 'Your network inspects HTTPS traffic, and the Azure CLI does not yet trust'
      Say 'your company''s certificate. Teaching it to trust what Windows already trusts...'

      $bundle = Join-Path $env:USERPROFILE '.azure\ca-bundle.pem'
      New-Item -ItemType Directory -Force (Split-Path $bundle) | Out-Null
      $lines = New-Object System.Collections.Generic.List[string]

      # Start from the CLI's own public certificate list...
      $certifi = (& $py -c 'import certifi; print(certifi.where())' 2>$null | Select-Object -First 1)
      if (-not $certifi) { $certifi = Join-Path (Split-Path $py) 'Lib\site-packages\certifi\cacert.pem' }
      if ($certifi -and (Test-Path $certifi)) { foreach ($l in (Get-Content $certifi)) { $lines.Add($l) } }

      # ...then add every certificate Windows trusts (never anything Windows distrusts).
      $distrusted = @{}
      Get-ChildItem 'Cert:\LocalMachine\Disallowed', 'Cert:\CurrentUser\Disallowed' -ErrorAction SilentlyContinue |
        ForEach-Object { $distrusted[$_.Thumbprint] = $true }
      $seen = @{}; $added = 0
      foreach ($store in 'Cert:\LocalMachine\Root', 'Cert:\CurrentUser\Root', 'Cert:\LocalMachine\CA', 'Cert:\CurrentUser\CA') {
        Get-ChildItem $store -ErrorAction SilentlyContinue | ForEach-Object {
          if ($_.NotAfter -lt (Get-Date)) { return }
          if ($seen.ContainsKey($_.Thumbprint) -or $distrusted.ContainsKey($_.Thumbprint)) { return }
          $seen[$_.Thumbprint] = $true
          $b64 = [Convert]::ToBase64String($_.RawData)
          $lines.Add('-----BEGIN CERTIFICATE-----')
          for ($i = 0; $i -lt $b64.Length; $i += 64) { $lines.Add($b64.Substring($i, [Math]::Min(64, $b64.Length - $i))) }
          $lines.Add('-----END CERTIFICATE-----')
          $added++
        }
      }
      Set-Content -Path $bundle -Value $lines -Encoding Ascii
      [Environment]::SetEnvironmentVariable('REQUESTS_CA_BUNDLE', $bundle, 'User')
      $env:REQUESTS_CA_BUNDLE = $bundle

      $out = & $py -c $probe 2>&1 | Out-String
      if ($LASTEXITCODE -eq 0) {
        Ok "Fixed - the Azure CLI now trusts what Windows trusts ($added certificates, saved for your user)"
        Say "Bundle: $bundle"
      } else {
        Bad 'Still cannot connect securely. See "Behind a company proxy" in README.md'
        Say ($out.Trim() -split "`n" | Select-Object -Last 1)
        return
      }
    } else {
      Wrn 'Could not reach Azure from the Azure CLI - the next step will show the error'
    }
  }

  # ---- 4. Sign in ------------------------------------------------------------
  Hdr '4. Azure sign-in'
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

  # ---- 5. Resource providers -------------------------------------------------
  Hdr '5. Resource providers'
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

  # ---- 6. Terraform ----------------------------------------------------------
  Hdr '6. Terraform'

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

  # ---- 7. Check the app ------------------------------------------------------
  Hdr '7. Check the app responds'
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
