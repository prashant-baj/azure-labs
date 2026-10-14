#!/usr/bin/env bash
# =============================================================================
#  Session 12 - deploy the triage AI feature to Azure (macOS / Linux / WSL)
#
#  Creates, in eastus (the lab policy allows eastus, eastus2, canadacentral):
#    resource group -> storage -> Function App (Flex Consumption, Python 3.11,
#    with Application Insights) -> system-assigned identity -> Key Vault (access
#    policies) -> the model key as a secret -> app settings with a Key Vault reference
#    -> zip deploy with a remote build.
#
#  Lab note: the lab subscription is cleaned roughly every four hours. Just run this
#  again - it is written to be re-run. Azure OpenAI is NOT allowed by the lab policy,
#  so the default model route is OpenRouter (the lab keys). See README.
#
#  USAGE
#    export MODEL_NAME="<model id your key can use>"      # required
#    export MODEL_BASE_URL="https://openrouter.ai/api/v1" # default
#    ./deploy/deploy.sh group1                            # asks for the key, hidden
# =============================================================================
set -euo pipefail
GROUP="${1:?Usage: ./deploy/deploy.sh <group-name, e.g. group1>}"
LOCATION="${LOCATION:-eastus}"
MODEL_BASE_URL="${MODEL_BASE_URL:-https://openrouter.ai/api/v1}"
: "${MODEL_NAME:?Set MODEL_NAME first, e.g. export MODEL_NAME=<model id>}"
if [ -z "${MODEL_API_KEY:-}" ]; then read -rsp "Model API key (input hidden): " MODEL_API_KEY; echo; fi

SUFFIX="$(printf '%05x' $(( (RANDOM * 32768 + RANDOM) % 1048576 )))"
SAFE="$(echo "$GROUP" | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9' | cut -c1-8)"
RG="rg-${SAFE}-triage"
ST="st${SAFE}tri${SUFFIX}"
APP="fn-${SAFE}-triage-${SUFFIX}"
KV="kv-${SAFE}-${SUFFIX}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

step() { echo; echo "==> $1"; }
step "Signed in as: $(az account show --query user.name -o tsv)  (subscription: $(az account show --query name -o tsv))"

step "1/7 Resource group $RG in $LOCATION"
az group create -n "$RG" -l "$LOCATION" -o none

step "2/7 Storage account $ST"
az storage account create -n "$ST" -g "$RG" -l "$LOCATION" --sku Standard_LRS --allow-blob-public-access false -o none

step "3/7 Function App $APP (Flex Consumption, Python 3.11, with Application Insights)"
az functionapp create -g "$RG" -n "$APP" --storage-account "$ST" \
  --flexconsumption-location "$LOCATION" --runtime python --runtime-version 3.11 -o none
PRINCIPAL="$(az functionapp identity assign -g "$RG" -n "$APP" --query principalId -o tsv)"

step "4/7 Key Vault $KV (access policies - the lab role cannot create role assignments)"
az keyvault create -n "$KV" -g "$RG" -l "$LOCATION" --enable-rbac-authorization false -o none
az keyvault set-policy -n "$KV" --object-id "$PRINCIPAL" --secret-permissions get -o none

step "5/7 Model key -> Key Vault secret 'model-api-key' (never into an app setting, never into git)"
KEYFILE="$(mktemp)"; printf '%s' "$MODEL_API_KEY" >"$KEYFILE"
az keyvault secret set --vault-name "$KV" -n model-api-key --file "$KEYFILE" -o none
rm -f "$KEYFILE"; unset MODEL_API_KEY

step "6/7 App settings (the key is a Key Vault reference, resolved by the app's identity)"
az functionapp config appsettings set -g "$RG" -n "$APP" -o none --settings \
  "MODEL_BASE_URL=$MODEL_BASE_URL" "MODEL_NAME=$MODEL_NAME" \
  "MODEL_API_KEY=@Microsoft.KeyVault(VaultName=$KV;SecretName=model-api-key)"

step "7/7 Zip deploy with a remote build"
ZIP="$(mktemp -d)/app.zip"
(cd "$HERE" && zip -qr "$ZIP" function_app.py host.json requirements.txt triage -x '*/__pycache__/*')
az functionapp deployment source config-zip -g "$RG" -n "$APP" --src "$ZIP" --build-remote true -o none

HOST="$(az functionapp show -g "$RG" -n "$APP" --query defaultHostName -o tsv)"
echo
echo "Deployed. Try it (the function key is like a password - do not commit it):"
echo "  curl -s -X POST \"https://$HOST/api/triage?code=<function key>\" -H 'Content-Type: application/json' \\"
echo "       -d '{\"message\": \"There is a leak in the lift lobby\"}'"
echo "Function key: az functionapp keys list -g $RG -n $APP --query functionKeys.default -o tsv"
echo "Check: \"suggested_by\" should say \"model\". If it says \"fake\", the Key Vault reference did not resolve - see README."
echo "Clean up: az group delete -n $RG --yes --no-wait"
