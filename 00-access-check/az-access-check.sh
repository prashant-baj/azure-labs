#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  az-access-check.sh  -  Azure CLI access smoke test
#
#  Confirms that the vlabs-provisioned Azure EA lab account can be reached from
#  the command line, that the Azure CLI is installed and up to date, and that
#  the account can both READ and WRITE (create/delete a resource group) in the
#  target subscription.
#
#  Runs on macOS / Linux / WSL. A PowerShell twin (az-access-check.ps1) exists
#  for native Windows.
#
#  AUTH: device-code login (works with MFA). The script prints a URL and a
#  one-time code; open the URL in a browser, enter the code, and sign in as the
#  lab user (loginId + loginpassword from the vlabs panel), approving MFA if
#  asked. Inline username/password login is NOT used - Microsoft now enforces
#  MFA and blocks that flow.
#
#  USAGE
#    ./az-access-check.sh
#
#  Override any default with an environment variable, e.g.
#    LAB_LOGIN_ID='...' LAB_SUBSCRIPTION_ID='...' ./az-access-check.sh
#
#  NOTE: the vlabs environment is wiped every ~4 hours. Re-run after a reset.
# =============================================================================

set -uo pipefail

# ---- Lab identity (defaults = current vlabs panel; override via env) ---------
LAB_LOGIN_ID="${LAB_LOGIN_ID:-prashant_1789717358725@nuveproeaazure.onmicrosoft.com}"
LAB_TENANT_ID="${LAB_TENANT_ID:-edcb69da-563d-4aa0-a13e-94be9a1d722d}"
LAB_SUBSCRIPTION_ID="${LAB_SUBSCRIPTION_ID:-b4ff8670-4b0c-484f-8565-74df13f030a6}"
LAB_REGION="${LAB_REGION:-eastus}"   # policy allows: eastus, eastus2, canadacentral
DO_WRITE_TEST="${DO_WRITE_TEST:-true}"       # set to false to skip RG create/delete

# ---- pretty output ----------------------------------------------------------
if [ -t 1 ]; then
  C_G=$'\033[0;32m'; C_R=$'\033[0;31m'; C_Y=$'\033[0;33m'; C_B=$'\033[0;36m'; C_0=$'\033[0m'
else
  C_G=""; C_R=""; C_Y=""; C_B=""; C_0=""
fi
PASS=0; FAIL=0; WARN=0
ok()   { echo "  ${C_G}[PASS]${C_0} $1"; PASS=$((PASS+1)); }
bad()  { echo "  ${C_R}[FAIL]${C_0} $1"; FAIL=$((FAIL+1)); }
warn() { echo "  ${C_Y}[WARN]${C_0} $1"; WARN=$((WARN+1)); }
hdr()  { echo; echo "${C_B}==> $1${C_0}"; }

echo "============================================================"
echo " Junior SWAT Labs - Azure CLI access check"
echo " $(date)"
echo "============================================================"

# ---- 1. Azure CLI installed -------------------------------------------------
hdr "1. Azure CLI installation"
if ! command -v az >/dev/null 2>&1; then
  bad "az not found on PATH."
  echo "       Install: https://learn.microsoft.com/cli/azure/install-azure-cli"
  echo "       macOS:  brew update && brew install azure-cli"
  echo "       Linux:  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
  echo
  echo "Cannot continue without the Azure CLI. Exiting."
  exit 1
fi
INSTALLED_VER="$(az version --output tsv --query '"azure-cli"' 2>/dev/null | tr -d '[:space:]')"
[ -n "$INSTALLED_VER" ] && ok "az installed (version ${INSTALLED_VER})" || warn "az installed but version could not be read."

# ---- 2. Version currency (best effort, needs internet) ----------------------
hdr "2. Version currency"
LATEST_VER="$(curl -fsSL --max-time 12 https://pypi.org/pypi/azure-cli/json 2>/dev/null \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['info']['version'])" 2>/dev/null \
  | tr -d '[:space:]')"
if [ -z "$LATEST_VER" ]; then
  warn "Could not reach PyPI to check the latest az version (offline or blocked). Skipping."
elif [ "$LATEST_VER" = "$INSTALLED_VER" ]; then
  ok "Azure CLI is the latest version (${INSTALLED_VER})."
else
  warn "Newer Azure CLI available: installed ${INSTALLED_VER}, latest ${LATEST_VER}."
  echo "       Upgrade with:  az upgrade   (or reinstall via your package manager)"
fi

# ---- 3. Sign-in details -----------------------------------------------------
hdr "3. Sign-in details"
# The value in [brackets] is the default from the vlabs panel - this is the
# account you will sign in as in the browser. Press Enter to accept, or type
# a different login id.
printf "  Sign in as [%s]: " "$LAB_LOGIN_ID"
read -r _ENTERED_ID
[ -n "$_ENTERED_ID" ] && LAB_LOGIN_ID="$_ENTERED_ID"
echo "  Login id : ${LAB_LOGIN_ID}"
echo "  Tenant   : ${LAB_TENANT_ID}"
echo "  Sub id   : ${LAB_SUBSCRIPTION_ID}"

# ---- 4. Login (device code - works with MFA) --------------------------------
hdr "4. az login (device code)"
az logout >/dev/null 2>&1 || true
echo "  A one-time code and a URL will appear below."
echo "  Open the URL in a browser, enter the code, then sign in as:"
echo "      ${LAB_LOGIN_ID}"
echo "  (use the loginpassword from the vlabs panel and approve MFA if asked)"
echo
if az login --use-device-code --tenant "$LAB_TENANT_ID" --output none; then
  ok "Logged in."
else
  bad "az login failed or was cancelled."
  echo "       - Enter the code and complete sign-in within the time limit."
  echo "       - Sign in as the loginId above with the loginpassword from the panel; approve MFA."
  echo "       - Retry, or run manually:  az login --use-device-code --tenant ${LAB_TENANT_ID}"
  echo
  echo "Login is required for the remaining checks. Exiting."
  exit 1
fi

# ---- 5. Select + verify subscription ---------------------------------------
hdr "5. Subscription"
if az account set --subscription "$LAB_SUBSCRIPTION_ID" >/dev/null 2>&1; then
  ok "Subscription set to ${LAB_SUBSCRIPTION_ID}."
else
  bad "Could not set subscription ${LAB_SUBSCRIPTION_ID}. Subscriptions visible to this login:"
  az account list --output table 2>/dev/null | sed 's/^/       /'
  exit 1
fi
CUR_SUB="$(az account show --query id -o tsv 2>/dev/null)"
CUR_TEN="$(az account show --query tenantId -o tsv 2>/dev/null)"
CUR_NAME="$(az account show --query name -o tsv 2>/dev/null)"
CUR_USER="$(az account show --query user.name -o tsv 2>/dev/null)"
echo "       Active subscription : ${CUR_NAME}"
echo "       Signed-in user      : ${CUR_USER}"
[ "$CUR_SUB" = "$LAB_SUBSCRIPTION_ID" ] && ok "Active subscription id matches expected." || warn "Active subscription id (${CUR_SUB}) differs from expected."
[ "$CUR_TEN" = "$LAB_TENANT_ID" ]       && ok "Tenant id matches expected."             || warn "Tenant id (${CUR_TEN}) differs from expected."

# ---- 6. READ access ---------------------------------------------------------
hdr "6. Read access"
# Count by lines (no JMESPath length() query - that misbehaved via the az.cmd shim).
LOC_OUT="$(az account list-locations -o tsv 2>&1)"; LOC_RC=$?
if [ $LOC_RC -eq 0 ] && [ -n "$LOC_OUT" ]; then
  LOC_COUNT="$(printf '%s\n' "$LOC_OUT" | grep -c .)"
  ok "Can list Azure locations (${LOC_COUNT} available)."
else
  bad "Could not list locations - the login may lack reader rights on this subscription."
  echo "$LOC_OUT" | sed 's/^/       /'
fi
RG_OUT="$(az group list -o tsv 2>&1)"; RG_RC=$?
if [ $RG_RC -eq 0 ]; then
  RG_COUNT="$(printf '%s' "$RG_OUT" | grep -c .)"   # 0 when the subscription has no groups yet
  ok "Can list resource groups (currently ${RG_COUNT})."
else
  bad "Could not list resource groups."
  echo "$RG_OUT" | sed 's/^/       /'
fi

# ---- 7. WRITE access (create then delete a throwaway resource group) --------
hdr "7. Write access (create + delete a resource group)"
if [ "$DO_WRITE_TEST" != "true" ]; then
  warn "Write test skipped (DO_WRITE_TEST=false)."
else
  TEST_RG="swat-readiness-$(date +%Y%m%d%H%M%S)"
  if az group create --name "$TEST_RG" --location "$LAB_REGION" \
        --tags purpose=readiness-check auto-delete=yes --output none 2>/tmp/rgcreate.$$; then
    ok "Created resource group ${TEST_RG} in ${LAB_REGION}."
    if az group delete --name "$TEST_RG" --yes --no-wait 2>/dev/null; then
      ok "Delete of ${TEST_RG} requested (running in background)."
    else
      warn "Created but could not delete ${TEST_RG}. Remove it manually or let the 4-hour cleanup handle it."
    fi
  else
    bad "Could not create a resource group in ${LAB_REGION}."
    sed 's/^/       /' /tmp/rgcreate.$$ 2>/dev/null
    echo "       -> May be an Azure Policy region restriction. Try another LAB_REGION (e.g. eastus, westeurope)."
  fi
  rm -f /tmp/rgcreate.$$ 2>/dev/null || true
fi

# ---- summary ----------------------------------------------------------------
echo
echo "============================================================"
echo " Result:  ${C_G}${PASS} passed${C_0}   ${C_Y}${WARN} warnings${C_0}   ${C_R}${FAIL} failed${C_0}"
if [ "$FAIL" -eq 0 ]; then
  echo " ${C_G}Lab account is reachable and usable from the CLI.${C_0}"
else
  echo " ${C_R}One or more checks failed - see above before running labs.${C_0}"
fi
echo "============================================================"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
