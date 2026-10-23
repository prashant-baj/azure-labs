<#
=============================================================================
  Junior SWAT Labs - Session 12 - let GitLab CI sign in to Azure with OIDC (Windows)

  Run ONCE per group, by a Maintainer, signed in with `az login` to the group's lab subscription.
    1. Creates an app registration for your GitLab project (or reuses it)
    2. Adds a federated credential: "trust GitLab ID tokens from <project>, branch main - nothing else"
    3. Tries to give it Contributor on the subscription. The lab role usually cannot - then it
       prints the one command your facilitator / vlabs runs for you.
    4. Prints the GitLab variable to add.  No secret is created anywhere.

  USAGE   ./setup-oidc.ps1 -Project mindsprint-group1/case-a-nova-retail [-Branch main]
=============================================================================
#>
param(
  [Parameter(Mandatory = $true)][string]$Project,
  [string]$Branch = "main"
)
$ErrorActionPreference = 'Continue'
$issuer = if ($env:GITLAB_URL) { $env:GITLAB_URL.TrimEnd('/') } else { 'https://gitlab.stackroute.in' }
function Ok  ($t) { Write-Host "  [ OK ] $t" -ForegroundColor Green }
function Wrn ($t) { Write-Host "  [WARN] $t" -ForegroundColor Yellow }
function Bad ($t) { Write-Host "  [FAIL] $t" -ForegroundColor Red }
function Hdr ($t) { Write-Host ""; Write-Host "==> $t" -ForegroundColor Cyan }

$name = "gitlab-" + ($Project -replace '/', '-')
$subject = "project_path:${Project}:ref_type:branch:ref:${Branch}"

Hdr "Before we start"
if (-not (Get-Command az -ErrorAction SilentlyContinue)) { Bad "Azure CLI (az) not found"; exit 1 }
az account show -o none 2>$null
if ($LASTEXITCODE -ne 0) { Bad "Not signed in - run: az login"; exit 1 }
$sub = az account show --query id -o tsv
$tenant = az account show --query tenantId -o tsv
Ok "Signed in as $(az account show --query user.name -o tsv)"
Ok "Subscription: $(az account show --query name -o tsv) ($sub)"
try {
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072 } catch {}
  $doc = Invoke-RestMethod -Uri "$issuer/.well-known/openid-configuration" -TimeoutSec 20
  if ($doc.issuer -eq $issuer) { Ok "GitLab publishes its OIDC keys at $issuer - Azure can check its tokens" }
  else { Wrn "Unexpected issuer '$($doc.issuer)' - tell your facilitator" }
} catch { Wrn "Could not read $issuer/.well-known/openid-configuration from here - carry on; if the pipeline later says AADSTS50166 or 700211, tell your facilitator" }

Hdr "1. App registration $name"
$appId = az ad app list --display-name $name --query "[0].appId" -o tsv 2>$null
if ($appId) { Ok "Already exists - reusing it ($appId)" }
else {
  $appId = az ad app create --display-name $name --query appId -o tsv
  if ($LASTEXITCODE -ne 0 -or -not $appId) { Bad "Could not create an app registration - ask your facilitator; your account may not be allowed to register apps."; exit 1 }
  Ok "Created ($appId)"
}
$spId = az ad sp show --id $appId --query id -o tsv 2>$null
if (-not $spId) { $spId = az ad sp create --id $appId --query id -o tsv }
Ok "Service principal ($spId)"

Hdr "2. Federated credential - trust $Project, branch $Branch, nothing else"
$have = az ad app federated-credential list --id $appId --query "[?subject=='$subject'] | length(@)" -o tsv 2>$null
if ($have -and [int]$have -gt 0) { Ok "Already there: $subject" }
else {
  $fc = [IO.Path]::GetTempFileName()
  $body = [ordered]@{
    name        = "gitlab-" + ($Branch -replace '[^a-zA-Z0-9-]', '-')
    issuer      = $issuer
    subject     = $subject
    audiences   = @('api://AzureADTokenExchange')
    description = "GitLab CI, $Project, branch $Branch"
  }
  [IO.File]::WriteAllText($fc, ($body | ConvertTo-Json -Compress), (New-Object Text.UTF8Encoding $false))
  az ad app federated-credential create --id $appId --parameters $fc -o none
  $rc = $LASTEXITCODE
  Remove-Item $fc -Force -ErrorAction SilentlyContinue
  if ($rc -ne 0) { Bad "Could not add the federated credential (see the message above)"; exit 1 }
  Ok "Added: $subject"
}

Hdr "3. Permission to deploy - Contributor on the subscription"
$hasRole = az role assignment list --assignee $appId --scope "/subscriptions/$sub" --query "[?roleDefinitionName=='Contributor'] | length(@)" -o tsv 2>$null
if ($hasRole -and [int]$hasRole -gt 0) { Ok "Already has Contributor" }
else {
  az role assignment create --assignee-object-id $spId --assignee-principal-type ServicePrincipal --role Contributor --scope "/subscriptions/$sub" -o none 2>$null
  if ($LASTEXITCODE -eq 0) { Ok "Contributor granted (it can take a few minutes to take effect)" }
  else {
    Wrn "Your lab role cannot grant roles - that is expected. Send this to your facilitator:"
    Write-Host ""
    Write-Host "      Group $($Project.Split('/')[0]): please run, as subscription Owner:"
    Write-Host "      az role assignment create --assignee $appId --role Contributor --scope /subscriptions/$sub"
    Write-Host ""
    Write-Host "      Until then the pipeline uses your group's service principal secret (README, fallback)."
  }
}

Hdr "4. Add this variable in GitLab"
Write-Host "  Project $Project -> Settings -> CI/CD -> Variables -> Add variable"
Write-Host ""
Write-Host "      Key:   AZURE_OIDC_CLIENT_ID"
Write-Host "      Value: $appId"
Write-Host "      Visibility: Visible  (it is an ID, not a secret)   Protect variable: ON   Expand: off"
Write-Host ""
Write-Host "  Your group already has AZURE_TENANT_ID ($tenant) and AZURE_SUBSCRIPTION_ID ($sub)."
Write-Host "  If not, add those two the same way."
Write-Host ""
Write-Host "  No secret was created. Only pipelines on $Branch of $Project can sign in as this app."
