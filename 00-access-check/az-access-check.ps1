<#
=============================================================================
  MindSprint Junior SWAT Engineering Program 2026 - Labs
  az-access-check.ps1  -  Azure CLI access smoke test  (Windows / PowerShell)

  Confirms that the vlabs-provisioned Azure EA lab account can be reached from
  the command line, that the Azure CLI is installed and up to date, and that
  the account can both READ and WRITE (create/delete a resource group) in the
  target subscription.

  A bash twin (az-access-check.sh) exists for macOS / Linux / WSL.

  AUTH: device-code login (works with MFA). The script prints a URL and a
  one-time code; open the URL in a browser, enter the code, and sign in as the
  lab user (loginId + loginpassword from the vlabs panel), approving MFA if
  asked. Inline username/password login is NOT used - Microsoft now enforces
  MFA and blocks that flow.

  USAGE  (Windows PowerShell 5.1 or PowerShell 7+)
    ./az-access-check.ps1

  Override any default:
    ./az-access-check.ps1 -LoginId '...' -SubscriptionId '...' -Region 'eastus'

  NOTE: the vlabs environment is wiped every ~4 hours. Re-run after a reset.

  If scripts are blocked, run once:
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
=============================================================================
#>
[CmdletBinding()]
param(
  [string]$LoginId        = $(if ($env:LAB_LOGIN_ID)        { $env:LAB_LOGIN_ID }        else { 'prashant_1789717358725@nuveproeaazure.onmicrosoft.com' }),
  [string]$TenantId       = $(if ($env:LAB_TENANT_ID)       { $env:LAB_TENANT_ID }       else { 'edcb69da-563d-4aa0-a13e-94be9a1d722d' }),
  [string]$SubscriptionId = $(if ($env:LAB_SUBSCRIPTION_ID) { $env:LAB_SUBSCRIPTION_ID } else { 'b4ff8670-4b0c-484f-8565-74df13f030a6' }),
  [string]$Region         = $(if ($env:LAB_REGION)          { $env:LAB_REGION }          else { 'eastus' }),   # policy allows: eastus, eastus2, canadacentral
  [switch]$SkipWriteTest
)

$ErrorActionPreference = 'Continue'
$script:Pass = 0; $script:Warn = 0; $script:Fail = 0

function Ok   ($m) { Write-Host "  [PASS] $m" -ForegroundColor Green;  $script:Pass++ }
function Bad  ($m) { Write-Host "  [FAIL] $m" -ForegroundColor Red;    $script:Fail++ }
function Warn ($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow; $script:Warn++ }
function Hdr  ($m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Azure CLI access check"
Write-Host (" " + (Get-Date))
Write-Host "============================================================"

# ---- 1. Azure CLI installed -------------------------------------------------
Hdr "1. Azure CLI installation"
$azCmd = Get-Command az -ErrorAction SilentlyContinue
if (-not $azCmd) {
  Bad "az not found on PATH."
  Write-Host "       Install: https://learn.microsoft.com/cli/azure/install-azure-cli"
  Write-Host "       Windows: winget install -e --id Microsoft.AzureCLI"
  Write-Host ""
  Write-Host "Cannot continue without the Azure CLI. Exiting."
  exit 1
}
$installedVer = ""
try { $installedVer = (az version --output json 2>$null | ConvertFrom-Json).'azure-cli' } catch {}
if ($installedVer) { Ok "az installed (version $installedVer)" } else { Warn "az installed but version could not be read." }

# ---- 2. Version currency (best effort, needs internet) ----------------------
Hdr "2. Version currency"
$latestVer = $null
try {
  # Windows PowerShell 5.1 may default to TLS 1.0; PyPI requires TLS 1.2+.
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
  $latestVer = (Invoke-RestMethod -Uri 'https://pypi.org/pypi/azure-cli/json' -TimeoutSec 12).info.version
} catch { $latestVer = $null }
if (-not $latestVer) {
  Warn "Could not reach PyPI to check the latest az version (offline or blocked). Skipping."
} elseif ($latestVer -eq $installedVer) {
  Ok "Azure CLI is the latest version ($installedVer)."
} else {
  Warn "Newer Azure CLI available: installed $installedVer, latest $latestVer."
  Write-Host "       Upgrade with:  az upgrade"
}

# ---- 3. Sign-in details -----------------------------------------------------
Hdr "3. Sign-in details"
# The value in [brackets] is the default from the vlabs panel - this is the
# account you will sign in as in the browser. Press Enter to accept, or type
# a different login id.
$enteredId = Read-Host -Prompt "  Sign in as [$LoginId]"
if ($enteredId) { $LoginId = $enteredId }
Write-Host "  Login id : $LoginId"
Write-Host "  Tenant   : $TenantId"
Write-Host "  Sub id   : $SubscriptionId"

# ---- 4. Login (device code - works with MFA) --------------------------------
Hdr "4. az login (device code)"
az logout 2>$null | Out-Null
Write-Host "  A one-time code and a URL will appear below."
Write-Host "  Open the URL in a browser, enter the code, then sign in as:"
Write-Host "      $LoginId"
Write-Host "  (use the loginpassword from the vlabs panel and approve MFA if asked)"
Write-Host "  Note: the sign-in prompt below may appear in red text - that is normal."
Write-Host ""
az login --use-device-code --tenant $TenantId --output none
if ($LASTEXITCODE -eq 0) {
  Ok "Logged in."
} else {
  Bad "az login failed or was cancelled."
  Write-Host "       - Enter the code and complete sign-in within the time limit."
  Write-Host "       - Sign in as the loginId above with the loginpassword from the panel; approve MFA."
  Write-Host "       - Retry, or run manually:  az login --use-device-code --tenant $TenantId"
  Write-Host ""
  Write-Host "Login is required for the remaining checks. Exiting."
  exit 1
}

# ---- 5. Select + verify subscription ---------------------------------------
Hdr "5. Subscription"
az account set --subscription $SubscriptionId 2>$null
if ($LASTEXITCODE -eq 0) {
  Ok "Subscription set to $SubscriptionId."
} else {
  Bad "Could not set subscription $SubscriptionId. Subscriptions visible to this login:"
  az account list --output table 2>$null | ForEach-Object { Write-Host "       $_" }
  exit 1
}
$acct = az account show --output json 2>$null | ConvertFrom-Json
Write-Host "       Active subscription : $($acct.name)"
Write-Host "       Signed-in user      : $($acct.user.name)"
if ($acct.id       -eq $SubscriptionId) { Ok "Active subscription id matches expected." } else { Warn "Active subscription id ($($acct.id)) differs from expected." }
if ($acct.tenantId -eq $TenantId)       { Ok "Tenant id matches expected." }             else { Warn "Tenant id ($($acct.tenantId)) differs from expected." }

# ---- 6. READ access ---------------------------------------------------------
Hdr "6. Read access"
# Count by lines (no JMESPath length() query - that misbehaved via the az.cmd shim).
$locOut = az account list-locations -o tsv 2>&1
if ($LASTEXITCODE -eq 0 -and $locOut) {
  $locCount = @($locOut | Where-Object { $_ -and $_.ToString().Trim() }).Count
  Ok "Can list Azure locations ($locCount available)."
} else {
  Bad "Could not list locations - the login may lack reader rights on this subscription."
  ($locOut | Out-String).TrimEnd().Split("`n") | ForEach-Object { if ($_) { Write-Host "       $_" } }
}
$rgOut = az group list -o tsv 2>&1
if ($LASTEXITCODE -eq 0) {
  $rgCount = @($rgOut | Where-Object { $_ -and $_.ToString().Trim() }).Count   # 0 when no groups yet
  Ok "Can list resource groups (currently $rgCount)."
} else {
  Bad "Could not list resource groups."
  ($rgOut | Out-String).TrimEnd().Split("`n") | ForEach-Object { if ($_) { Write-Host "       $_" } }
}

# ---- 7. WRITE access (create then delete a throwaway resource group) --------
Hdr "7. Write access (create + delete a resource group)"
if ($SkipWriteTest) {
  Warn "Write test skipped (-SkipWriteTest)."
} else {
  $testRg = "swat-readiness-" + (Get-Date -Format "yyyyMMddHHmmss")
  $createOut = az group create --name $testRg --location $Region --tags purpose=readiness-check auto-delete=yes --output none 2>&1
  if ($LASTEXITCODE -eq 0) {
    Ok "Created resource group $testRg in $Region."
    az group delete --name $testRg --yes --no-wait 2>$null
    if ($LASTEXITCODE -eq 0) { Ok "Delete of $testRg requested (running in background)." }
    else { Warn "Created but could not delete $testRg. Remove it manually or let the 4-hour cleanup handle it." }
  } else {
    Bad "Could not create a resource group in $Region."
    ($createOut | Out-String).TrimEnd().Split("`n") | ForEach-Object { Write-Host "       $_" }
    Write-Host "       -> May be an Azure Policy region restriction. Try another -Region (e.g. eastus, westeurope)."
  }
}

# ---- summary ----------------------------------------------------------------
Write-Host ""
Write-Host "============================================================"
Write-Host " Result:  " -NoNewline
Write-Host "$script:Pass passed" -ForegroundColor Green -NoNewline
Write-Host "   " -NoNewline
Write-Host "$script:Warn warnings" -ForegroundColor Yellow -NoNewline
Write-Host "   " -NoNewline
Write-Host "$script:Fail failed" -ForegroundColor Red
if ($script:Fail -eq 0) {
  Write-Host " Lab account is reachable and usable from the CLI." -ForegroundColor Green
} else {
  Write-Host " One or more checks failed - see above before running labs." -ForegroundColor Red
}
Write-Host "============================================================"
if ($script:Fail -eq 0) { exit 0 } else { exit 1 }
