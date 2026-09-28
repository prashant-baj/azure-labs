#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  00-access-check / az-access-check.sh   (macOS / Linux / WSL)
#
#  Confirms that the vlabs Azure lab account can be reached from the command
#  line: the Azure CLI is installed and current, this machine can talk to Azure
#  securely (also behind a company proxy), and the account can both READ and
#  WRITE (create and delete a resource group) in its subscription.
#
#    ./az-access-check.sh
#
#  SIGN-IN: device code, which works with MFA. The script prints a URL and a
#  one-time code; open the URL, enter the code, and sign in with the loginId
#  and loginpassword from your vlabs panel. No password is typed into or
#  stored by this script.
#
#  Optional settings (environment variables):
#    LAB_REGION            region for the write test (default eastus;
#                          the lab allows eastus, eastus2, canadacentral)
#    LAB_SUBSCRIPTION_ID   pick this subscription if the login sees several
#    LAB_TENANT_ID         sign in to this tenant
#    LAB_SKIP_WRITE_TEST   set to 1 to skip the create/delete test
#
#  A PowerShell twin (az-access-check.ps1 / .cmd) exists for Windows.
#  The vlabs environment is recycled about every 4 hours. Re-run after a reset.
# =============================================================================

set -uo pipefail
cd "$(dirname "$0")" || exit 1

REGION="${LAB_REGION:-eastus}"
SUB_WANT="${LAB_SUBSCRIPTION_ID:-}"
TENANT="${LAB_TENANT_ID:-}"
case "${LAB_SKIP_WRITE_TEST:-}" in 1|true|yes) SKIP_WRITE=1 ;; *) SKIP_WRITE=0 ;; esac

if [ -t 1 ]; then
  C_G=$'\033[0;32m'; C_R=$'\033[0;31m'; C_Y=$'\033[0;33m'; C_B=$'\033[0;36m'; C_0=$'\033[0m'
else C_G=""; C_R=""; C_Y=""; C_B=""; C_0=""; fi
PASS=0; FAIL=0; WARN=0
ok()   { echo "  ${C_G}[PASS]${C_0} $1"; PASS=$((PASS+1)); }
bad()  { echo "  ${C_R}[FAIL]${C_0} $1"; FAIL=$((FAIL+1)); }
warn() { echo "  ${C_Y}[WARN]${C_0} $1"; WARN=$((WARN+1)); }
hdr()  { echo; echo "${C_B}==> $1${C_0}"; }
say()  { echo "       $1"; }
indent() { sed 's/^/       /'; }
summary() {
  echo
  echo "============================================================"
  echo " Result:  ${C_G}${PASS} passed${C_0}   ${C_Y}${WARN} warnings${C_0}   ${C_R}${FAIL} failed${C_0}"
  if [ "$FAIL" -eq 0 ]; then echo " ${C_G}Lab account is reachable and usable from the CLI.${C_0}"
  else echo " ${C_R}One or more checks failed - see above before running labs.${C_0}"; fi
  echo "============================================================"
  [ "$FAIL" -eq 0 ] && exit 0 || exit 1
}

echo "============================================================"
echo " Junior SWAT Labs - 00 - Azure CLI access check"
echo " $(date)"
echo "============================================================"

# ---- 1. Azure CLI installed -------------------------------------------------
hdr "1. Azure CLI installation"
if ! command -v az >/dev/null 2>&1; then
  bad "az not found on PATH."
  say "Install: https://learn.microsoft.com/cli/azure/install-azure-cli"
  say "macOS:  brew update && brew install azure-cli"
  say "Linux:  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
  summary
fi
INSTALLED_VER="$(az version --output tsv --query '"azure-cli"' 2>/dev/null | tr -d '[:space:]')"
if [ -n "$INSTALLED_VER" ]; then ok "az installed (version ${INSTALLED_VER})"
else warn "az installed but version could not be read."; fi

# ---- 2. Version currency (best effort) --------------------------------------
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
  say "Upgrade with:  az upgrade   (or your package manager, e.g. brew upgrade azure-cli)"
fi

# ---- 3. Certificates --------------------------------------------------------
# Shared with the other labs: ../tools/fix-company-proxy.sh. Only if your network
# inspects HTTPS, it makes the Azure CLI trust what this machine already trusts.
hdr "3. Certificates"
if [ -f ../tools/fix-company-proxy.sh ]; then
  # shellcheck source=/dev/null
  FIX_PROXY_NO_RUN=1 . ../tools/fix-company-proxy.sh
  if fix_company_proxy auto; then ok "The Azure CLI can connect to Azure securely."
  else bad "The Azure CLI cannot connect to Azure securely - see \"Behind a company proxy\" in README.md"; summary; fi
else
  warn "tools/fix-company-proxy.sh not found - skipping this check (download the whole repository, not one folder)."
fi

# ---- 4. Sign in (device code - works with MFA) ------------------------------
hdr "4. Sign in"
printf "  Your loginId from the vlabs panel (Enter to skip): "
read -r LOGIN_ID
LOGIN_ID="$(echo "${LOGIN_ID:-}" | tr -d '[:space:]')"
az logout >/dev/null 2>&1 || true
say "A URL and a one-time code will appear below. Open the URL in a browser,"
say "enter the code, and sign in with the loginId and loginpassword from your"
say "vlabs panel. Approve MFA if asked."
echo
if [ -n "$TENANT" ]; then LOGIN_OK=0; az login --use-device-code --tenant "$TENANT" --output none && LOGIN_OK=1
else LOGIN_OK=0; az login --use-device-code --output none && LOGIN_OK=1; fi
if [ "$LOGIN_OK" -ne 1 ]; then
  bad "Sign-in failed or was cancelled."
  say "- Enter the code and finish signing in before it times out."
  say "- Use loginpassword from the panel (not temporaryAccessPassword or password)."
  say "- If the lab was just reset: press Start in vlabs, wait for \"Start - Complete\", run this again."
  summary
fi
ok "Signed in."

# ---- 5. Subscription --------------------------------------------------------
hdr "5. Subscription"
if [ -n "$SUB_WANT" ] && ! az account set --subscription "$SUB_WANT" >/dev/null 2>&1; then
  warn "Could not select LAB_SUBSCRIPTION_ID ${SUB_WANT} - using the default one."
fi
ACCT="$(az account show --query '[id, name, tenantId, state, user.name]' -o tsv 2>/dev/null | tr '\n' '\t')"
if [ -z "$ACCT" ]; then
  bad "Signed in, but no subscription is visible to this login."
  say "Check the vlabs panel shows \"Start - Complete\" - the lab may still be starting."
  summary
fi
IFS=$'\t' read -r CUR_SUB CUR_NAME CUR_TEN CUR_STATE CUR_USER <<< "$ACCT"
say "Signed-in user : ${CUR_USER}"
say "Subscription   : ${CUR_NAME} (${CUR_SUB})"
say "Tenant         : ${CUR_TEN}"
if [ "$CUR_STATE" = "Enabled" ]; then ok "Subscription is active."; else bad "Subscription state is '${CUR_STATE}'."; fi
if [ -n "$LOGIN_ID" ]; then
  if [ "$CUR_USER" = "$LOGIN_ID" ]; then ok "Signed in as the loginId you entered."
  else warn "Signed in as ${CUR_USER}, not ${LOGIN_ID}. If that is your company account, run this again and pick the lab account in the browser."; fi
elif [[ "$CUR_USER" != *onmicrosoft.com ]]; then
  warn "Signed in as ${CUR_USER}. Lab accounts end in onmicrosoft.com - if this is your company account, run this again and pick the lab account."
fi

# ---- 6. Read access ---------------------------------------------------------
hdr "6. Read access"
LOC_OUT="$(az account list-locations -o tsv 2>&1)"; LOC_RC=$?
if [ $LOC_RC -eq 0 ] && [ -n "$LOC_OUT" ]; then
  ok "Can list Azure locations ($(printf '%s\n' "$LOC_OUT" | grep -c .) available)."
else
  bad "Could not list locations - the login may lack reader rights on this subscription."
  indent <<< "$LOC_OUT"
fi
RG_OUT="$(az group list -o tsv 2>&1)"; RG_RC=$?
if [ $RG_RC -eq 0 ]; then
  ok "Can list resource groups (currently $(printf '%s' "$RG_OUT" | grep -c .))."   # 0 on a fresh lab
else
  bad "Could not list resource groups."
  indent <<< "$RG_OUT"
fi

# ---- 7. Write access (create then delete a throwaway resource group) --------
hdr "7. Write access (create + delete a resource group)"
if [ "$SKIP_WRITE" = 1 ]; then
  warn "Write test skipped (LAB_SKIP_WRITE_TEST)."
else
  TEST_RG="swat-readiness-$(date +%Y%m%d%H%M%S)"
  if CREATE_OUT="$(az group create --name "$TEST_RG" --location "$REGION" \
        --tags purpose=readiness-check auto-delete=yes --output none 2>&1)"; then
    ok "Created resource group ${TEST_RG} in ${REGION}."
    if az group delete --name "$TEST_RG" --yes --no-wait 2>/dev/null; then
      ok "Delete of ${TEST_RG} requested (running in background)."
    else
      warn "Created but could not delete ${TEST_RG}. Remove it in the portal, or let the 4-hour reset handle it."
    fi
  else
    bad "Could not create a resource group in ${REGION}."
    indent <<< "$CREATE_OUT"
    say "The lab allows only eastus, eastus2 and canadacentral - see ../lab-constraints.md"
  fi
fi

summary
