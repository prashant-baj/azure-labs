#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  02-azure-resources-test / run-test.sh   (macOS / Linux / WSL)
#
#  Runs the whole serverless-stack test in the right order, and prepares this
#  machine so it also works behind a company proxy that inspects HTTPS traffic.
#
#    ./run-test.sh            deploy and check
#    ./run-test.sh destroy    tear everything down
#
#  If (and only if) your network inspects HTTPS, it writes
#  ~/.azure/ca-bundle.pem - the certificates your operating system already
#  trusts - and points the Azure CLI at it for this run. Nothing is bypassed.
#  A PowerShell twin (run-test.ps1 / run-test.cmd) exists for Windows.
# =============================================================================

set -uo pipefail
MODE="${1:-apply}"
cd "$(dirname "$0")" || exit 1

if [ -t 1 ]; then
  C_G=$'\033[0;32m'; C_R=$'\033[0;31m'; C_Y=$'\033[0;33m'; C_B=$'\033[0;36m'; C_0=$'\033[0m'
else C_G=""; C_R=""; C_Y=""; C_B=""; C_0=""; fi
hdr() { echo; echo "${C_B}==> $1${C_0}"; }
ok()  { echo "  ${C_G}[ OK ]${C_0} $1"; }
wrn() { echo "  ${C_Y}[WARN]${C_0} $1"; }
bad() { echo "  ${C_R}[FAIL]${C_0} $1"; }
say() { echo "         $1"; }

[ -f main.tf ] || { bad "Run this from the 02-azure-resources-test folder (main.tf not found)."; exit 1; }

echo "============================================================"
echo " Junior SWAT Labs - 02 - Azure resources test ($MODE)"
echo "============================================================"

# ---- 1. Tools ----------------------------------------------------------------
hdr "1. Tools"
for t in az terraform curl; do
  if command -v "$t" >/dev/null 2>&1; then ok "$t found"
  else bad "$t not found - run 01-prereqs-check first"; exit 1; fi
done

# ---- 2. Certificates ---------------------------------------------------------
hdr "2. Certificates"
PY="$(az --version 2>/dev/null | sed -n "s/^Python location '\(.*\)'$/\1/p" | head -1)"
PROBE="import requests; requests.get('https://management.azure.com', timeout=20)"
if [ -z "$PY" ]; then
  wrn "Could not locate the Azure CLI's Python - skipping the certificate check"
else
  OUT="$("$PY" -c "$PROBE" 2>&1)"; RC=$?
  if [ $RC -eq 0 ]; then
    ok "The Azure CLI can reach Azure securely"
  elif echo "$OUT" | grep -q CERTIFICATE_VERIFY_FAILED; then
    say "Your network inspects HTTPS traffic, and the Azure CLI does not yet trust"
    say "your company's certificate. Teaching it to trust what this machine trusts..."
    BUNDLE="$HOME/.azure/ca-bundle.pem"; mkdir -p "$HOME/.azure"; : > "$BUNDLE"
    CERTIFI="$("$PY" -c 'import certifi; print(certifi.where())' 2>/dev/null)"
    [ -n "$CERTIFI" ] && [ -f "$CERTIFI" ] && cat "$CERTIFI" >> "$BUNDLE"
    if [ "$(uname -s)" = "Darwin" ]; then
      # Company root certificates are installed into the System keychain on managed Macs.
      security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain \
        /Library/Keychains/System.keychain >> "$BUNDLE" 2>/dev/null
    else
      for f in /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt; do
        [ -f "$f" ] && { cat "$f" >> "$BUNDLE"; break; }
      done
    fi
    export REQUESTS_CA_BUNDLE="$BUNDLE"
    OUT="$("$PY" -c "$PROBE" 2>&1)"; RC=$?
    if [ $RC -eq 0 ]; then
      ok "Fixed - the Azure CLI now trusts what this machine trusts"
      say "To keep this for new terminals, add to your shell profile:"
      say "  export REQUESTS_CA_BUNDLE=\"$BUNDLE\""
    else
      bad "Still cannot connect securely. See \"Behind a company proxy\" in README.md"
      say "$(echo "$OUT" | tail -1)"
      exit 1
    fi
  else
    wrn "Could not reach Azure from the Azure CLI - the next step will show the error"
  fi
fi

# ---- 3. Sign in --------------------------------------------------------------
hdr "3. Azure sign-in"
if ! az group list -o none 2>/dev/null; then
  say "Signing you in - pick your lab account (loginId) when the sign-in page opens."
  if ! az login -o none; then
    wrn "Browser sign-in did not complete - trying device-code sign-in instead"
    az login --use-device-code -o none
  fi
  if ! az group list -o none 2>/dev/null; then
    bad "Signed in, but the lab subscription is not reachable."
    say "Check the vlabs panel shows \"Start - Complete\" (the lab resets every ~4 hours)."
    exit 1
  fi
fi
SUB_ID="$(az account show --query id -o tsv)"
SUB_NAME="$(az account show --query name -o tsv)"
export ARM_SUBSCRIPTION_ID="$SUB_ID"
ok "Using subscription $SUB_NAME ($SUB_ID)"

# ---- 4. Resource providers ---------------------------------------------------
hdr "4. Resource providers"
PENDING=""
RPS="Microsoft.OperationalInsights Microsoft.Insights Microsoft.ContainerRegistry Microsoft.App
     Microsoft.DocumentDB Microsoft.ServiceBus Microsoft.KeyVault Microsoft.Storage"
if [ "$MODE" = "destroy" ]; then RPS=""; ok "Not needed for destroy - skipped"; fi
for rp in $RPS; do
  st="$(az provider show -n "$rp" --query registrationState -o tsv 2>/dev/null)"
  if [ "$st" = "Registered" ]; then ok "$rp"
  else az provider register -n "$rp" -o none 2>/dev/null; PENDING="$PENDING $rp"; fi
done
for rp in $PENDING; do
  say "Waiting for $rp to register..."
  if az provider register -n "$rp" --wait -o none; then ok "$rp registered"
  else bad "$rp could not be registered"; exit 1; fi
done

# ---- 5. Terraform ------------------------------------------------------------
hdr "5. Terraform"
# State from an earlier lab session points at a subscription that no longer
# exists (the lab resets every ~4 hours). Set it aside instead of fighting it.
if [ -f terraform.tfstate ]; then
  CUR="$(echo "$SUB_ID" | tr 'A-Z' 'a-z')"
  OTHER="$(grep -oiE '/subscriptions/[0-9a-f-]{36}' terraform.tfstate | tr 'A-Z' 'a-z' | sort -u \
           | grep -v "/subscriptions/$CUR\$" || true)"
  if [ -n "$OTHER" ]; then
    STAMP="$(date +%Y%m%d-%H%M%S)"
    mv terraform.tfstate "terraform.tfstate.$STAMP.old"
    [ -f terraform.tfstate.backup ] && mv terraform.tfstate.backup "terraform.tfstate.backup.$STAMP.old"
    ok "Found state from an earlier lab session (that subscription is gone) - set it aside, starting fresh"
    if [ "$MODE" = "destroy" ]; then say "Nothing to destroy: the lab reset already removed those resources."; exit 0; fi
  fi
fi

terraform init -input=false || { bad "terraform init failed - see the message above, and \"Troubleshooting\" in README.md"; exit 1; }

if [ "$MODE" = "destroy" ]; then
  say "Terraform will list what it is about to delete. Type yes to confirm."
  if terraform destroy; then ok "Everything this test created has been deleted"
  else bad "terraform destroy did not finish - run ./run-test.sh destroy again"; exit 1; fi
  exit 0
fi

say "Read the plan - on a fresh run it says \"Plan: 11 to add, 0 to change, 0 to destroy\". Then type yes."
terraform apply || { bad "terraform apply failed - see the error above, and ../lab-constraints.md for the usual causes"; exit 1; }

# ---- 6. Check the app --------------------------------------------------------
hdr "6. Check the app responds"
URL="$(terraform output -raw app_url)"
CA_OPT=""; [ -n "${REQUESTS_CA_BUNDLE:-}" ] && CA_OPT="--cacert $REQUESTS_CA_BUNDLE"
UP=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  # shellcheck disable=SC2086
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 $CA_OPT "$URL")"
  [ "$code" = "200" ] && { UP=1; break; }
  say "Waiting for the app to start ($i/12)..."; sleep 10
done
if [ $UP -eq 1 ]; then ok "App returned 200 at $URL"
else bad "App did not respond at $URL - check the Container App in the portal"; fi

echo
echo "============================================================"
echo " Next: open the resource group in the Azure portal and compare it"
echo " with images/expected-resources.png (README step 3b)."
echo " When you are done: ./run-test.sh destroy"
echo "============================================================"
