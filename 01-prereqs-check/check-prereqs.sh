#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-prereqs.sh  -  Local toolchain readiness check  (macOS / Linux / WSL)
#
#  Verifies the tools the Azure labs need are installed locally and are a
#  reasonable version. Run this BEFORE the Azure access check (00-access-check).
#
#  USAGE
#    chmod +x check-prereqs.sh    # first time only
#    ./check-prereqs.sh
#
#  Exit code is non-zero if any REQUIRED tool is missing or too old.
#  A PowerShell twin (check-prereqs.ps1) exists for native Windows.
# =============================================================================

set -uo pipefail

if [ -t 1 ]; then
  C_G=$'\033[0;32m'; C_R=$'\033[0;31m'; C_Y=$'\033[0;33m'; C_B=$'\033[0;36m'; C_0=$'\033[0m'
else C_G=""; C_R=""; C_Y=""; C_B=""; C_0=""; fi
PASS=0; WARN=0; FAIL=0
ok()   { echo "  ${C_G}[ OK ]${C_0} $1"; PASS=$((PASS+1)); }
warn() { echo "  ${C_Y}[WARN]${C_0} $1"; WARN=$((WARN+1)); }
bad()  { echo "  ${C_R}[FAIL]${C_0} $1"; FAIL=$((FAIL+1)); }
hdr()  { echo; echo "${C_B}==> $1${C_0}"; }

# extract first x.y or x.y.z from stdin
ver() { grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1; }
# ge A B  -> success (0) if A >= B
ge()  { [ "$1" = "$2" ] && return 0; [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]; }

# check_ver NAME VERSION MIN  (empty VERSION => installed but unknown version)
check_ver() {
  local name="$1" v="$2" min="$3"
  if [ -z "$v" ]; then ok "$name: installed (version unknown)"; return; fi
  if [ -n "$min" ] && ! ge "$v" "$min"; then
    warn "$name: $v installed - $min+ recommended"
  else
    ok "$name: $v"
  fi
}

echo "============================================================"
echo " Junior SWAT Labs - local toolchain check"
echo " $(uname -s) $(uname -m) - $(date)"
echo "============================================================"

# --- Required -------------------------------------------------------------
hdr "Required tools"

# Azure CLI
if command -v az >/dev/null 2>&1; then
  check_ver "Azure CLI (az)" "$(az version -o tsv --query '"azure-cli"' 2>/dev/null | ver)" "2.60.0"
else bad "Azure CLI (az): not installed  -> https://learn.microsoft.com/cli/azure/install-azure-cli"; fi

# Git
if command -v git >/dev/null 2>&1; then
  check_ver "Git" "$(git --version 2>/dev/null | ver)" "2.30.0"
else bad "Git: not installed  -> https://git-scm.com/downloads"; fi

# Python
if command -v python3 >/dev/null 2>&1; then
  check_ver "Python" "$(python3 --version 2>&1 | ver)" "3.10.0"
elif command -v python >/dev/null 2>&1; then
  check_ver "Python" "$(python --version 2>&1 | ver)" "3.10.0"
else bad "Python 3: not installed  -> https://www.python.org/downloads/"; fi

# Node.js
if command -v node >/dev/null 2>&1; then
  check_ver "Node.js" "$(node --version 2>/dev/null | ver)" "18.0.0"
else bad "Node.js: not installed  -> https://nodejs.org/ (LTS)"; fi

# npm
if command -v npm >/dev/null 2>&1; then
  check_ver "npm" "$(npm --version 2>/dev/null | ver)" "9.0.0"
else bad "npm: not installed (ships with Node.js)"; fi

# Docker
if command -v docker >/dev/null 2>&1; then
  check_ver "Docker" "$(docker --version 2>/dev/null | ver)" "24.0.0"
  if docker info >/dev/null 2>&1; then ok "Docker daemon: running"
  else warn "Docker daemon: not running - start Docker Desktop / the docker service"; fi
else bad "Docker: not installed  -> https://docs.docker.com/get-docker/"; fi

# Terraform
if command -v terraform >/dev/null 2>&1; then
  check_ver "Terraform" "$(terraform version 2>/dev/null | head -1 | ver)" "1.6.0"
else bad "Terraform: not installed  -> https://developer.hashicorp.com/terraform/install"; fi

# Helm
if command -v helm >/dev/null 2>&1; then
  check_ver "Helm" "$(helm version --short 2>/dev/null | ver)" "3.12.0"
else bad "Helm: not installed  -> https://helm.sh/docs/intro/install/"; fi

# --- Recommended ----------------------------------------------------------
hdr "Recommended tools"

# kubectl (for AKS labs)
if command -v kubectl >/dev/null 2>&1; then
  KV="$(kubectl version --client -o json 2>/dev/null | ver)"
  [ -z "$KV" ] && KV="$(kubectl version --client 2>/dev/null | ver)"
  check_ver "kubectl" "$KV" "1.28.0"
else warn "kubectl: not installed (needed for AKS labs)  -> https://kubernetes.io/docs/tasks/tools/"; fi

# Azure Functions Core Tools (for Functions labs)
if command -v func >/dev/null 2>&1; then
  check_ver "Azure Functions Core Tools" "$(func --version 2>/dev/null | ver)" "4.0.0"
else warn "Azure Functions Core Tools (func): not installed (needed for Functions labs)  -> https://learn.microsoft.com/azure/azure-functions/functions-run-local"; fi

# --- Summary --------------------------------------------------------------
echo
echo "============================================================"
echo " Result:  ${C_G}${PASS} ok${C_0}   ${C_Y}${WARN} warnings${C_0}   ${C_R}${FAIL} failed${C_0}"
if [ "$FAIL" -eq 0 ]; then
  echo " ${C_G}Required toolchain is ready.${C_0} Next: run the Azure access check (00-access-check)."
else
  echo " ${C_R}Install the missing required tools above, then re-run.${C_0}"
fi
echo "============================================================"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
