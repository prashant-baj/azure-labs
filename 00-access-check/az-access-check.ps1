<#
=============================================================================
  MindSprint Junior SWAT Engineering Program 2026 - Labs
  00-access-check / az-access-check.ps1   (Windows)

  Confirms that the vlabs Azure lab account can be reached from the command
  line: the Azure CLI is installed and current, this machine can talk to Azure
  securely (also behind a company proxy), and the account can both READ and
  WRITE (create and delete a resource group) in its subscription.

  Start it with   az-access-check.cmd   (double-click, or run it in this folder)
  or, from a terminal in this folder:
                  Get-Content .\az-access-check.ps1 -Raw | Invoke-Expression

  SIGN-IN: device code, which works with MFA. The script prints a URL and a
  one-time code; open the URL, enter the code, and sign in with the loginId
  and loginpassword from your vlabs panel. No password is typed into or
  stored by this script.

  Optional settings (environment variables):
    LAB_REGION            region for the write test (default eastus;
                          the lab allows eastus, eastus2, canadacentral)
    LAB_SUBSCRIPTION_ID   pick this subscription if the login sees several
    LAB_TENANT_ID         sign in to this tenant
    LAB_SKIP_WRITE_TEST   set to 1 to skip the create/delete test

  The vlabs environment is recycled about every 4 hours. Re-run after a reset.
=============================================================================
#>
# No param() block, so it also runs via Get-Content | Invoke-Expression on
# machines where PowerShell execution policy blocks .ps1 files.

function Invoke-AccessCheck {
  $ErrorActionPreference = 'Continue'
  $region   = if ($env:LAB_REGION) { $env:LAB_REGION } else { 'eastus' }
  $subWant  = $env:LAB_SUBSCRIPTION_ID
  $tenant   = $env:LAB_TENANT_ID
  $skipWrite = $env:LAB_SKIP_WRITE_TEST -in '1', 'true', 'yes'

  $script:Pass = 0; $script:Warn = 0; $script:Fail = 0
  function Ok   ($m) { Write-Host "  [PASS] $m" -ForegroundColor Green;  $script:Pass++ }
  function Bad  ($m) { Write-Host "  [FAIL] $m" -ForegroundColor Red;    $script:Fail++ }
  function Warn ($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow; $script:Warn++ }
  function Hdr  ($m) { Write-Host ''; Write-Host "==> $m" -ForegroundColor Cyan }
  function Say  ($m) { Write-Host "       $m" }
  function Summary {
    Write-Host ''
    Write-Host '============================================================'
    Write-Host ' Result:  ' -NoNewline
    Write-Host "$script:Pass passed" -ForegroundColor Green -NoNewline
    Write-Host '   ' -NoNewline
    Write-Host "$script:Warn warnings" -ForegroundColor Yellow -NoNewline
    Write-Host '   ' -NoNewline
    Write-Host "$script:Fail failed" -ForegroundColor Red
    if ($script:Fail -eq 0) { Write-Host ' Lab account is reachable and usable from the CLI.' -ForegroundColor Green }
    else { Write-Host ' One or more checks failed - see above before running labs.' -ForegroundColor Red }
    Write-Host '============================================================'
  }

  if ($PSScriptRoot) { Set-Location $PSScriptRoot }

  Write-Host '============================================================'
  Write-Host ' Junior SWAT Labs - 00 - Azure CLI access check'
  Write-Host (' ' + (Get-Date))
  Write-Host '============================================================'

  # ---- 1. Azure CLI installed -----------------------------------------------
  Hdr '1. Azure CLI installation'
  if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Bad 'az not found on PATH.'
    Say 'Install: https://learn.microsoft.com/cli/azure/install-azure-cli'
    Say 'Windows: winget install -e --id Microsoft.AzureCLI'
    Say '(If installs need approval at your company, ask IT - then run this again.)'
    Summary; return
  }
  $installedVer = ''
  try { $installedVer = (az version --output json 2>$null | ConvertFrom-Json).'azure-cli' } catch {}
  if ($installedVer) { Ok "az installed (version $installedVer)" } else { Warn 'az installed but version could not be read.' }

  # ---- 2. Version currency (best effort) ------------------------------------
  Hdr '2. Version currency'
  $latestVer = $null
  try {
    # Windows PowerShell 5.1 may default to TLS 1.0; PyPI requires TLS 1.2+.
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072 } catch {}
    $latestVer = (Invoke-RestMethod -Uri 'https://pypi.org/pypi/azure-cli/json' -TimeoutSec 12).info.version
  } catch { $latestVer = $null }
  if (-not $latestVer) {
    Warn 'Could not reach PyPI to check the latest az version (offline or blocked). Skipping.'
  } elseif ($latestVer -eq $installedVer) {
    Ok "Azure CLI is the latest version ($installedVer)."
  } else {
    Warn "Newer Azure CLI available: installed $installedVer, latest $latestVer."
    Say 'Upgrade with:  az upgrade   (or ask IT, if your company manages installs)'
  }

  # ---- 3. Network and certificates ------------------------------------------
  # Shared with the other labs: ..\tools\fix-company-proxy.ps1. It uses your
  # company proxy for this run, and - only if your network inspects HTTPS -
  # makes the Azure CLI trust what Windows already trusts. See tools\README.md.
  Hdr '3. Network and certificates'
  $helper = Join-Path (Get-Location).Path '..\tools\fix-company-proxy.ps1'
  if (Test-Path $helper) {
    $ProxyFixNoRun = $true
    Get-Content -Raw $helper | Invoke-Expression
    $trusted = Invoke-CompanyProxyFix -Action 'auto' | Select-Object -Last 1
    if ($trusted) { Ok 'The Azure CLI can connect to Azure securely.' }
    else { Bad 'The Azure CLI cannot connect to Azure securely - see "Behind a company proxy" in README.md'; Summary; return }
  } else {
    Warn 'tools\fix-company-proxy.ps1 not found - skipping this check (download the whole repository, not one folder).'
  }

  # ---- 4. Sign in (device code - works with MFA) ----------------------------
  Hdr '4. Sign in'
  $loginId = Read-Host -Prompt '  Your loginId from the vlabs panel (Enter to skip)'
  if ($loginId) { $loginId = $loginId.Trim() }
  az logout 2>$null | Out-Null
  Say 'A URL and a one-time code will appear below. Open the URL in a browser,'
  Say 'enter the code, and sign in with the loginId and loginpassword from your'
  Say 'vlabs panel. Approve MFA if asked. (The message may be in red - that is normal.)'
  Write-Host ''
  if ($tenant) { az login --use-device-code --tenant $tenant --output none }
  else         { az login --use-device-code --output none }
  if ($LASTEXITCODE -ne 0) {
    Bad 'Sign-in failed or was cancelled.'
    Say '- Enter the code and finish signing in before it times out.'
    Say '- Use loginpassword from the panel (not temporaryAccessPassword or password).'
    Say '- If the lab was just reset: press Start in vlabs, wait for "Start - Complete", run this again.'
    Summary; return
  }
  Ok 'Signed in.'

  # ---- 5. Subscription ------------------------------------------------------
  Hdr '5. Subscription'
  if ($subWant) {
    az account set --subscription $subWant 2>$null
    if ($LASTEXITCODE -ne 0) { Warn "Could not select LAB_SUBSCRIPTION_ID $subWant - using the default one." }
  }
  $acct = $null
  try { $acct = az account show --output json 2>$null | ConvertFrom-Json } catch {}
  if (-not $acct) {
    Bad 'Signed in, but no subscription is visible to this login.'
    Say 'Check the vlabs panel shows "Start - Complete" - the lab may still be starting.'
    Summary; return
  }
  Say "Signed-in user : $($acct.user.name)"
  Say "Subscription   : $($acct.name) ($($acct.id))"
  Say "Tenant         : $($acct.tenantId)"
  if ($acct.state -eq 'Enabled') { Ok 'Subscription is active.' } else { Bad "Subscription state is '$($acct.state)'." }
  if ($loginId) {
    if ($acct.user.name -eq $loginId) { Ok 'Signed in as the loginId you entered.' }
    else { Warn "Signed in as $($acct.user.name), not $loginId. If that is your company account, run this again and pick the lab account in the browser." }
  } elseif ($acct.user.name -notmatch 'onmicrosoft\.com$') {
    Warn "Signed in as $($acct.user.name). Lab accounts end in onmicrosoft.com - if this is your company account, run this again and pick the lab account."
  }

  # ---- 6. Read access -------------------------------------------------------
  Hdr '6. Read access'
  # Count by lines (no JMESPath length() query - that misbehaves via the az.cmd shim).
  $locOut = az account list-locations -o tsv 2>&1
  if ($LASTEXITCODE -eq 0 -and $locOut) {
    $locCount = @($locOut | Where-Object { $_ -and $_.ToString().Trim() }).Count
    Ok "Can list Azure locations ($locCount available)."
  } else {
    Bad 'Could not list locations - the login may lack reader rights on this subscription.'
    ($locOut | Out-String).TrimEnd().Split("`n") | ForEach-Object { if ($_) { Say $_ } }
  }
  $rgOut = az group list -o tsv 2>&1
  if ($LASTEXITCODE -eq 0) {
    $rgCount = @($rgOut | Where-Object { $_ -and $_.ToString().Trim() }).Count   # 0 on a fresh lab
    Ok "Can list resource groups (currently $rgCount)."
  } else {
    Bad 'Could not list resource groups.'
    ($rgOut | Out-String).TrimEnd().Split("`n") | ForEach-Object { if ($_) { Say $_ } }
  }

  # ---- 7. Write access (create then delete a throwaway resource group) ------
  Hdr '7. Write access (create + delete a resource group)'
  if ($skipWrite) {
    Warn 'Write test skipped (LAB_SKIP_WRITE_TEST).'
  } else {
    $testRg = 'swat-readiness-' + (Get-Date -Format 'yyyyMMddHHmmss')
    $createOut = az group create --name $testRg --location $region --tags purpose=readiness-check auto-delete=yes --output none 2>&1
    if ($LASTEXITCODE -eq 0) {
      Ok "Created resource group $testRg in $region."
      az group delete --name $testRg --yes --no-wait 2>$null
      if ($LASTEXITCODE -eq 0) { Ok "Delete of $testRg requested (running in background)." }
      else { Warn "Created but could not delete $testRg. Remove it in the portal, or let the 4-hour reset handle it." }
    } else {
      Bad "Could not create a resource group in $region."
      ($createOut | Out-String).TrimEnd().Split("`n") | ForEach-Object { if ($_) { Say $_ } }
      Say 'The lab allows only eastus, eastus2 and canadacentral - see ../lab-constraints.md'
    }
  }

  Summary
}

Invoke-AccessCheck
