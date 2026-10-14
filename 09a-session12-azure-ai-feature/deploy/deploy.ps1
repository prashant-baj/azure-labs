# =============================================================================
#  Session 12 - deploy the triage AI feature to Azure (Windows PowerShell 7)
#  Same steps as deploy.sh. Re-run it after the lab clean-up (about every four hours).
#
#  USAGE
#    $env:MODEL_NAME = "<model id your key can use>"
#    $env:MODEL_BASE_URL = "https://openrouter.ai/api/v1"     # default
#    ./deploy/deploy.ps1 -Group group1                         # asks for the key, hidden
# =============================================================================
param([Parameter(Mandatory = $true)][string]$Group, [string]$Location = "eastus")
$ErrorActionPreference = "Stop"
function Step($t) { Write-Host ""; Write-Host "==> $t" -ForegroundColor Cyan }
function Az { & az @args; if ($LASTEXITCODE -ne 0) { throw "az $($args -join ' ') failed" } }

$BaseUrl = if ($env:MODEL_BASE_URL) { $env:MODEL_BASE_URL } else { "https://openrouter.ai/api/v1" }
if (-not $env:MODEL_NAME) { throw "Set `$env:MODEL_NAME first" }
$Secure = if ($env:MODEL_API_KEY) { ConvertTo-SecureString $env:MODEL_API_KEY -AsPlainText -Force } else { Read-Host "Model API key (input hidden)" -AsSecureString }

$Safe   = ($Group.ToLower() -replace '[^a-z0-9]', ''); if ($Safe.Length -gt 8) { $Safe = $Safe.Substring(0, 8) }
$Suffix = -join ((48..57) + (97..122) | Get-Random -Count 5 | ForEach-Object { [char]$_ })
$Rg = "rg-$Safe-triage"; $St = "st${Safe}tri$Suffix"; $App = "fn-$Safe-triage-$Suffix"; $Kv = "kv-$Safe-$Suffix"
$Here = Split-Path -Parent $PSScriptRoot

Step "Signed in as: $(az account show --query user.name -o tsv)"
Step "1/7 Resource group $Rg in $Location";  Az group create -n $Rg -l $Location -o none
Step "2/7 Storage account $St";              Az storage account create -n $St -g $Rg -l $Location --sku Standard_LRS --allow-blob-public-access false -o none
Step "3/7 Function App $App (Flex Consumption, Python 3.11)"
Az functionapp create -g $Rg -n $App --storage-account $St --flexconsumption-location $Location --runtime python --runtime-version 3.11 -o none
$Principal = az functionapp identity assign -g $Rg -n $App --query principalId -o tsv

Step "4/7 Key Vault $Kv (access policies)"
Az keyvault create -n $Kv -g $Rg -l $Location --enable-rbac-authorization false -o none
Az keyvault set-policy -n $Kv --object-id $Principal --secret-permissions get -o none

Step "5/7 Model key -> Key Vault secret 'model-api-key'"
$KeyFile = New-TemporaryFile
[IO.File]::WriteAllText($KeyFile, [Net.NetworkCredential]::new('', $Secure).Password)
try { Az keyvault secret set --vault-name $Kv -n model-api-key --file $KeyFile -o none } finally { Remove-Item $KeyFile -Force }

Step "6/7 App settings (key as a Key Vault reference)"
Az functionapp config appsettings set -g $Rg -n $App -o none --settings `
  "MODEL_BASE_URL=$BaseUrl" "MODEL_NAME=$($env:MODEL_NAME)" "MODEL_API_KEY=@Microsoft.KeyVault(VaultName=$Kv;SecretName=model-api-key)"

Step "7/7 Zip deploy with a remote build"
$Stage = Join-Path ([IO.Path]::GetTempPath()) "triage-$Suffix"; New-Item -ItemType Directory $Stage | Out-Null
Copy-Item (Join-Path $Here "function_app.py"), (Join-Path $Here "host.json"), (Join-Path $Here "requirements.txt") $Stage
Copy-Item (Join-Path $Here "triage") $Stage -Recurse
Get-ChildItem $Stage -Recurse -Directory -Filter "__pycache__" | Remove-Item -Recurse -Force
$Zip = "$Stage.zip"; Compress-Archive -Path (Join-Path $Stage "*") -DestinationPath $Zip -Force
Az functionapp deployment source config-zip -g $Rg -n $App --src $Zip --build-remote true -o none

$HostName = az functionapp show -g $Rg -n $App --query defaultHostName -o tsv
Write-Host ""
Write-Host "Deployed: https://$HostName/api/triage?code=<function key>"
Write-Host "Function key: az functionapp keys list -g $Rg -n $App --query functionKeys.default -o tsv"
Write-Host "Check: 'suggested_by' should say 'model'. 'fake' means the Key Vault reference did not resolve - see README."
Write-Host "Clean up: az group delete -n $Rg --yes --no-wait"
