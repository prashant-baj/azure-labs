#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  tools/fix-company-proxy.sh   (macOS / Linux / WSL)
#
#  Makes the Azure CLI, Git and Node/npm work on a company network that
#  inspects HTTPS traffic - without switching any security check off.
#
#    ./fix-company-proxy.sh           check, and fix only if needed
#    ./fix-company-proxy.sh --undo    reverse every change it made
#    ./fix-company-proxy.sh --force   build the bundle even if no problem is seen
#
#  00-access-check and 02-azure-resources-test run the check for you.
#
#  What it changes - only when your network inspects HTTPS; user-level only,
#  no sudo, nothing installed:
#    * writes ~/.azure/ca-bundle.pem: the usual public certificates plus the
#      ones your operating system trusts
#    * adds REQUESTS_CA_BUNDLE (Azure CLI, pip, Python) and NODE_EXTRA_CA_CERTS
#      (Node, npm) to your shell profile, in a clearly marked block
#    * git config --global http.sslCAInfo ~/.azure/ca-bundle.pem
#  Settings that already point somewhere else are left alone.
#
#  Scripts that include it:  FIX_PROXY_NO_RUN=1 . ../tools/fix-company-proxy.sh
#                            fix_company_proxy auto || exit 1
# =============================================================================

fix_company_proxy() {
  local action="${1:-auto}"
  local g="" y="" r="" z=""
  if [ -t 1 ]; then g=$'\033[0;32m'; y=$'\033[0;33m'; r=$'\033[0;31m'; z=$'\033[0m'; fi
  pf_ok()  { echo "  ${g}[ OK ]${z} $1"; }
  pf_wrn() { echo "  ${y}[WARN]${z} $1"; }
  pf_bad() { echo "  ${r}[FAIL]${z} $1"; }
  pf_say() { echo "         $1"; }

  local dir="$HOME/.azure"
  local bundle="$dir/ca-bundle.pem"
  local record="$dir/ca-bundle-changes.txt"
  local begin="# >>> junior-swat-labs: company certificates >>>"
  local end="# <<< junior-swat-labs: company certificates <<<"
  local profile
  case "$(basename "${SHELL:-bash}")" in
    zsh)  profile="$HOME/.zshrc" ;;
    bash) if [ "$(uname -s)" = "Darwin" ]; then profile="$HOME/.bash_profile"; else profile="$HOME/.bashrc"; fi ;;
    *)    profile="$HOME/.profile" ;;
  esac

  # ------------------------------------------------------------------ undo ----
  if [ "$action" = "undo" ]; then
    local f
    for f in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
      if [ -f "$f" ] && grep -qF "$begin" "$f"; then
        sed "/^# >>> junior-swat-labs: company certificates >>>/,/^# <<< junior-swat-labs: company certificates <<</d" "$f" > "$f.swat-tmp" \
          && cat "$f.swat-tmp" > "$f" && rm -f "$f.swat-tmp"
        pf_ok "Removed the certificate settings from $f"
      fi
    done
    if [ -f "$record" ] && grep -qx "git http.sslCAInfo" "$record" \
       && [ "$(git config --global --get http.sslCAInfo 2>/dev/null)" = "$bundle" ]; then
      git config --global --unset http.sslCAInfo
      pf_ok "Removed git http.sslCAInfo"
    fi
    [ "${REQUESTS_CA_BUNDLE:-}" = "$bundle" ]  && unset REQUESTS_CA_BUNDLE
    [ "${NODE_EXTRA_CA_CERTS:-}" = "$bundle" ] && unset NODE_EXTRA_CA_CERTS
    rm -f "$bundle" "$record"
    pf_ok "Undone - Azure CLI, Git and Node are back to their own certificate lists"
    return 0
  fi

  # ------------------------------------------------------------ how to test ----
  # The Azure CLI's own Python is the best test: it is exactly what fails.
  # If the Azure CLI is not installed, Node (which also keeps its own list) will do.
  local py="" has_node=0 detail=""
  if command -v az >/dev/null 2>&1; then
    py="$(az --version 2>/dev/null | sed -n "s/^Python location '\(.*\)'$/\1/p" | head -1)"
  fi
  command -v node >/dev/null 2>&1 && has_node=1

  local state=""
  pf_probe() {   # sets state: ok | untrusted | neterror | unknown  (and detail)
    local out
    if [ -n "$py" ]; then
      if out="$("$py" -c "import requests; requests.get('https://management.azure.com', timeout=20)" 2>&1)"; then
        state=ok; return; fi
      detail="$(echo "$out" | tail -1)"
      if echo "$out" | grep -q CERTIFICATE_VERIFY_FAILED; then state=untrusted; else state=neterror; fi
      return
    fi
    if [ "$has_node" = 1 ]; then
      if out="$(node -e "var r=require('https').get('https://management.azure.com',function(){process.exit(0)});r.on('error',function(e){console.log(e.code||e.message);process.exit(1)});r.setTimeout(20000,function(){console.log('TIMEOUT');process.exit(1)})" 2>&1)"; then
        state=ok; return; fi
      detail="$out"
      if echo "$out" | grep -qE 'SELF_SIGNED_CERT_IN_CHAIN|UNABLE_TO_GET_ISSUER_CERT|UNABLE_TO_VERIFY_LEAF_SIGNATURE|CERT_UNTRUSTED'; then
        state=untrusted; else state=neterror; fi
      return
    fi
    state=unknown
  }

  # -------------------------------------------- point the tools at the bundle ----
  pf_set_tools() {
    mkdir -p "$dir"
    local lines="" v cur
    for v in REQUESTS_CA_BUNDLE NODE_EXTRA_CA_CERTS; do
      cur="$(printenv "$v" || true)"
      if [ -n "$cur" ] && [ "$cur" != "$bundle" ]; then
        pf_wrn "$v is already set to $cur - left unchanged"
        [ "$v" = REQUESTS_CA_BUNDLE ] || continue
        pf_say "Using the new bundle for this run only. If the Azure CLI fails in a new window, remove that setting."
      else
        lines="${lines}export $v=\"\$HOME/.azure/ca-bundle.pem\""$'\n'
      fi
      export "$v=$bundle"
    done
    if [ -n "$lines" ] && ! { [ -f "$profile" ] && grep -qF "$begin" "$profile"; }; then
      printf '\n%s\n%s%s\n' "$begin" "$lines" "$end" >> "$profile"
      pf_ok "Added the certificate settings to $profile (new terminals pick them up)"
    fi
    if command -v git >/dev/null 2>&1; then
      local cainfo backend
      cainfo="$(git config --global --get http.sslCAInfo 2>/dev/null)"
      backend="$(git config --global --get http.sslBackend 2>/dev/null)"
      if [ "$cainfo" = "$bundle" ]; then
        pf_ok "Git already uses your certificate bundle"
      elif [ -z "$cainfo" ] && [ -z "$backend" ]; then
        git config --global http.sslCAInfo "$bundle"
        grep -qx "git http.sslCAInfo" "$record" 2>/dev/null || echo "git http.sslCAInfo" >> "$record"
        pf_ok "Git now trusts what this machine trusts (http.sslCAInfo)"
      else
        pf_wrn "Git already has its own certificate setting (sslCAInfo=$cainfo sslBackend=$backend) - left unchanged"
      fi
    fi
  }

  # ------------------------------------------------------------------ check ----
  pf_probe
  if [ "$action" != "force" ]; then
    case "$state" in
      ok)
        if [ "${REQUESTS_CA_BUNDLE:-}" = "$bundle" ] && [ -s "$bundle" ]; then
          pf_ok "Secure connections work, using your certificate bundle"; pf_set_tools
        else
          pf_ok "Secure connections to Azure work - no certificate changes needed"
        fi
        return 0 ;;
      neterror)
        pf_wrn "Could not reach Azure - not a certificate problem. The next step will show the error."
        [ -n "$detail" ] && pf_say "$detail"
        return 0 ;;
      unknown)
        pf_wrn "Could not test certificates - neither the Azure CLI nor Node is installed"
        return 0 ;;
    esac
    pf_say "Your network inspects HTTPS traffic, and your tools do not yet trust your"
    pf_say "company's certificate. Teaching them to trust what this machine already trusts..."
  else
    pf_say "Building the certificate bundle (forced)..."
  fi

  # ----------------------------------------------------------- build bundle ----
  mkdir -p "$dir"
  local tmp="$bundle.tmp" certifi="" f
  : > "$tmp"
  # 1. The usual public certificates - from the Azure CLI, or else from Node.
  [ -n "$py" ] && certifi="$("$py" -c 'import certifi; print(certifi.where())' 2>/dev/null)"
  if [ -n "$certifi" ] && [ -f "$certifi" ]; then
    cat "$certifi" >> "$tmp"
  elif [ "$has_node" = 1 ]; then
    node -e "process.stdout.write(require('tls').rootCertificates.join('\n')+'\n')" >> "$tmp" 2>/dev/null
  fi
  # 2. What this machine trusts. On managed Macs the company certificate is in the System keychain.
  if [ "$(uname -s)" = "Darwin" ]; then
    security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain \
      /Library/Keychains/System.keychain >> "$tmp" 2>/dev/null
  else
    for f in /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt /etc/ssl/cert.pem; do
      [ -f "$f" ] && { cat "$f" >> "$tmp"; break; }
    done
  fi
  mv "$tmp" "$bundle"
  pf_ok "Wrote $bundle ($(grep -c 'BEGIN CERTIFICATE' "$bundle") certificates)"

  pf_set_tools

  # --------------------------------------------------------------- re-test ----
  pf_probe
  case "$state" in
    ok)      pf_ok "Fixed - your tools now trust what this machine trusts"; return 0 ;;
    unknown) return 0 ;;
  esac
  pf_bad "Still cannot connect securely. See \"Behind a company proxy\" in tools/README.md"
  [ -n "$detail" ] && pf_say "$detail"
  return 1
}

# Run directly (not sourced by a lab script)?
if [ -z "${FIX_PROXY_NO_RUN:-}" ] && [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    --undo)  ACTION=undo ;;
    --force) ACTION=force ;;
    "")      ACTION=auto ;;
    *)       echo "Usage: $0 [--undo|--force]"; exit 2 ;;
  esac
  echo "============================================================"
  echo " Junior SWAT Labs - company proxy and certificates ($ACTION)"
  echo "============================================================"
  if fix_company_proxy "$ACTION"; then
    echo
    [ "$ACTION" = undo ] || echo " If anything changed above, open a NEW terminal so your tools pick it up."
    exit 0
  fi
  exit 1
fi
