#!/usr/bin/env bash
# =============================================================================
#  Junior SWAT Labs - Session 12 - let GitLab CI sign in to Azure with OIDC (macOS / Linux / WSL)
#
#  Run ONCE per group, by a Maintainer, signed in with `az login` to the group's lab subscription.
#    1. Creates an app registration for your GitLab project (or reuses it)
#    2. Adds a federated credential: "trust GitLab ID tokens from <project>, branch main - nothing else"
#    3. Tries to give it Contributor on the subscription. The lab role usually cannot - then it
#       prints the one command your facilitator / vlabs runs for you.
#    4. Prints the GitLab variable to add.  No secret is created anywhere.
#
#  USAGE   ./setup-oidc.sh <gitlab project path> [branch]
#  e.g.    ./setup-oidc.sh mindsprint-group1/case-a-nova-retail
# =============================================================================
set -uo pipefail
PROJECT="${1:-}"; BRANCH="${2:-main}"
ISSUER="${GITLAB_URL:-https://gitlab.stackroute.in}"; ISSUER="${ISSUER%/}"
[ -n "$PROJECT" ] || { echo "Usage: ./setup-oidc.sh <gitlab project path, e.g. mindsprint-group1/case-a-nova-retail> [branch]"; exit 1; }
if [ -t 1 ]; then G=$'\033[0;32m'; Y=$'\033[0;33m'; R=$'\033[0;31m'; B=$'\033[0;36m'; N=$'\033[0m'; else G=""; Y=""; R=""; B=""; N=""; fi
ok()  { echo "  ${G}[ OK ]${N} $1"; }
warn(){ echo "  ${Y}[WARN]${N} $1"; }
bad() { echo "  ${R}[FAIL]${N} $1"; }
hdr() { echo; echo "${B}==> $1${N}"; }

NAME="gitlab-$(echo "$PROJECT" | tr '/' '-')"
SUBJECT="project_path:${PROJECT}:ref_type:branch:ref:${BRANCH}"

hdr "Before we start"
command -v az >/dev/null || { bad "Azure CLI (az) not found"; exit 1; }
az account show -o none 2>/dev/null || { bad "Not signed in - run: az login"; exit 1; }
SUB=$(az account show --query id -o tsv); TENANT=$(az account show --query tenantId -o tsv)
ok "Signed in as $(az account show --query user.name -o tsv)"
ok "Subscription: $(az account show --query name -o tsv) ($SUB)"
if curl -fsS -m 20 "$ISSUER/.well-known/openid-configuration" 2>/dev/null | grep -q "\"issuer\":\"$ISSUER\""; then
  ok "GitLab publishes its OIDC keys at $ISSUER - Azure can check its tokens"
else
  warn "Could not read $ISSUER/.well-known/openid-configuration from here - carry on; if the pipeline later says AADSTS50166 or 700211, tell your facilitator"
fi

hdr "1. App registration $NAME"
APP_ID=$(az ad app list --display-name "$NAME" --query "[0].appId" -o tsv 2>/dev/null)
if [ -n "$APP_ID" ]; then ok "Already exists - reusing it ($APP_ID)"
else
  APP_ID=$(az ad app create --display-name "$NAME" --query appId -o tsv 2>/tmp/setup-oidc.err) \
    || { bad "Could not create an app registration:"; sed 's/^/         /' /tmp/setup-oidc.err; echo "         Ask your facilitator - your account may not be allowed to register apps."; exit 1; }
  ok "Created ($APP_ID)"
fi
SP_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv 2>/dev/null)
[ -n "$SP_ID" ] || SP_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)
ok "Service principal ($SP_ID)"

hdr "2. Federated credential - trust $PROJECT, branch $BRANCH, nothing else"
HAVE=$(az ad app federated-credential list --id "$APP_ID" --query "[?subject=='$SUBJECT'] | length(@)" -o tsv 2>/dev/null)
if [ "${HAVE:-0}" != "0" ]; then ok "Already there: $SUBJECT"
else
  FC="$(mktemp)"
  printf '{"name":"gitlab-%s","issuer":"%s","subject":"%s","audiences":["api://AzureADTokenExchange"],"description":"GitLab CI, %s, branch %s"}' \
    "$(printf '%s' "$BRANCH" | tr -c 'a-zA-Z0-9-' '-')" "$ISSUER" "$SUBJECT" "$PROJECT" "$BRANCH" > "$FC"
  if az ad app federated-credential create --id "$APP_ID" --parameters "$FC" -o none 2>/tmp/setup-oidc.err; then ok "Added: $SUBJECT"
  else bad "Could not add the federated credential:"; sed 's/^/         /' /tmp/setup-oidc.err; rm -f "$FC"; exit 1; fi
  rm -f "$FC"
fi

hdr "3. Permission to deploy - Contributor on the subscription"
if az role assignment list --assignee "$APP_ID" --scope "/subscriptions/$SUB" --query "[?roleDefinitionName=='Contributor'] | length(@)" -o tsv 2>/dev/null | grep -q '^[1-9]'; then
  ok "Already has Contributor"
elif az role assignment create --assignee-object-id "$SP_ID" --assignee-principal-type ServicePrincipal \
       --role Contributor --scope "/subscriptions/$SUB" -o none 2>/dev/null; then
  ok "Contributor granted (it can take a few minutes to take effect)"
else
  warn "Your lab role cannot grant roles - that is expected. Send this to your facilitator:"
  echo
  echo "      Group ${PROJECT%%/*}: please run, as subscription Owner:"
  echo "      az role assignment create --assignee $APP_ID --role Contributor --scope /subscriptions/$SUB"
  echo
  echo "      Until then the pipeline uses your group's service principal secret (README, fallback)."
fi

hdr "4. Add this variable in GitLab"
echo "  Project $PROJECT -> Settings -> CI/CD -> Variables -> Add variable"
echo
echo "      Key:   AZURE_OIDC_CLIENT_ID"
echo "      Value: $APP_ID"
echo "      Visibility: Visible  (it is an ID, not a secret)   Protect variable: ON   Expand: off"
echo
echo "  Your group already has AZURE_TENANT_ID ($TENANT) and AZURE_SUBSCRIPTION_ID ($SUB)."
echo "  If not, add those two the same way."
echo
echo "  No secret was created. Only pipelines on $BRANCH of $PROJECT can sign in as this app."
