#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-workshop-cd.sh  -  Lab 09c: is the test deployment wired into the workshop
#                           repo, merged, recorded - and cleaned up?  (macOS / Linux / WSL)
#
#  Checks files and records in git. It cannot see Azure or the GitLab pipeline - the
#  record in infra-test/DEPLOYED.md is your evidence, with the pipeline links in it.
#
#  USAGE
#    chmod +x check-workshop-cd.sh          # first time only
#    ./check-workshop-cd.sh [path-to-your-workshop-repo]
#
#  Exit code is non-zero only if something required is missing - or a secret is committed.
#  A PowerShell twin (check-workshop-cd.ps1) exists for native Windows.
# =============================================================================

set -uo pipefail
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_G=$'\033[0;32m'; C_R=$'\033[0;31m'; C_Y=$'\033[0;33m'; C_B=$'\033[0;36m'; C_0=$'\033[0m'
else C_G=""; C_R=""; C_Y=""; C_B=""; C_0=""; fi
PASS=0; WARN=0; FAIL=0
ok()   { echo "  ${C_G}[ OK ]${C_0} $1"; PASS=$((PASS+1)); }
warn() { echo "  ${C_Y}[WARN]${C_0} $1"; WARN=$((WARN+1)); }
bad()  { echo "  ${C_R}[FAIL]${C_0} $1"; FAIL=$((FAIL+1)); }
hdr()  { echo; echo "${C_B}==> $1${C_0}"; }

REPO="${1:-.}"
[ -d "$REPO" ] || { echo "Path not found: $REPO"; exit 1; }
REPO="$(cd "$REPO" && pwd)"
CI="$REPO/.gitlab-ci.yml"; INFRA="$REPO/infra-test"; REC="$INFRA/DEPLOYED.md"

echo "============================================================"
echo " Junior SWAT Labs - 09c - CD of a test resource - check"
echo " $REPO"
echo "============================================================"
[ -d "$REPO/.git" ] || { bad "Not a git repository"; exit 1; }

# --- 1. Files ----------------------------------------------------------------------
hdr "1 · The pipeline and the Terraform"
HAVE_FILES=yes
for f in ci/cd-test.yml infra-test/versions.tf infra-test/variables.tf infra-test/main.tf infra-test/outputs.tf; do
  if [ -f "$REPO/$f" ]; then ok "$f"; else bad "$f missing - run setup-workshop-cd"; HAVE_FILES=no; fi
done
if [ -f "$INFRA/versions.tf" ]; then
  grep -qE 'backend[[:space:]]+"azurerm"' "$INFRA/versions.tf" && ok "State kept in Azure (backend azurerm), not on a laptop" \
    || warn "No backend \"azurerm\" in infra-test/versions.tf - the pipeline cannot keep state between runs"
fi
LEAK=$(git -C "$REPO" grep -nIE '(client_secret|ARM_CLIENT_SECRET|AZURE_CLIENT_SECRET)[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9~._-]{20,}|glpat-[A-Za-z0-9_-]{20,}' -- . ':!*.md' 2>/dev/null | head -3)
[ -z "$LEAK" ] && ok "No Azure secrets or tokens committed" || { bad "A secret looks committed - remove it, and tell your facilitator so it is rotated:"; echo "$LEAK" | sed 's/^/         /'; }
STATE=$(git -C "$REPO" ls-files | grep -E '(^|/)(\.terraform/|[^/]*\.tfstate|[^/]*\.tfplan$)' | head -3)
[ -z "$STATE" ] && ok "No Terraform state, plans or .terraform/ in git" || { bad "Terraform state or plans are committed (they can hold secrets): $STATE"; }

# --- 2. Pipeline -------------------------------------------------------------------
hdr "2 · The pipeline includes it"
INCLUDED=no
if [ ! -f "$CI" ]; then bad "No .gitlab-ci.yml"
else
  grep -q 'ci/cd-test.yml' "$CI" && { ok "ci/cd-test.yml included in .gitlab-ci.yml"; INCLUDED=yes; } \
    || bad "ci/cd-test.yml not included - add  - local: ci/cd-test.yml  to include:"
  if grep -qE '^stages:' "$CI"; then
    ST="$(awk '/^stages:/{f=1} f{print} f && !/^stages:/ && /^[^[:space:]#-]/{exit}' "$CI" | head -15)"
    for s in test deploy; do
      echo "$ST" | grep -qE "(^|[[,[:space:]-])$s([],[:space:]]|$)" && ok "stage $s exists" || bad "stage $s missing from stages: - the pipeline will not even start"
    done
  else ok "No stages: list - the defaults include test and deploy"; fi
  grep -qE '^(test|unit|pytest|lint|build)[A-Za-z0-9:_-]*:|^[[:space:]]+stage:[[:space:]]*(build|check|test)[[:space:]]*$' "$CI" && ok "There are lint/test jobs - the deploy waits for them" \
    || warn "No test job besides the Terraform check - the deploy only waits for what is there"
fi
if command -v terraform >/dev/null && [ -d "$INFRA" ]; then
  ( cd "$INFRA" && terraform fmt -check -recursive >/dev/null 2>&1 ) && ok "terraform fmt clean" || warn "terraform fmt would change files - cdtest:validate will fail: run  terraform fmt -recursive  in infra-test/"
fi

# --- 3. Merged and deployed ----------------------------------------------------------
hdr "3 · Merged, deployed, recorded"
DEF="$(git -C "$REPO" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"; DEF="${DEF:-main}"
MAINREF=""; for r in "refs/remotes/origin/$DEF" "refs/heads/$DEF"; do git -C "$REPO" rev-parse -q --verify "$r" >/dev/null && { MAINREF="$r"; break; }; done
ON_MAIN=no
if [ -n "$MAINREF" ] && git -C "$REPO" cat-file -e "$MAINREF:ci/cd-test.yml" 2>/dev/null; then
  ON_MAIN=yes; ok "On $DEF - merged, so main's pipeline deploys"
  ADDED=$(git -C "$REPO" log --format=%H --diff-filter=A "$MAINREF" -- ci/cd-test.yml 2>/dev/null | tail -1)
  if [ -n "$ADDED" ] && git -C "$REPO" rev-list --first-parent "$MAINREF" | grep -q "^$ADDED"; then
    warn "ci/cd-test.yml was committed straight onto $DEF, not merged from a branch - was the merge request skipped?"
  else ok "Arrived by merge request"; fi
else
  warn "Not on $DEF yet - push the branch and merge the merge request"
fi
PIPE=no; SITE=no; DESTROYED=no; SECOND=no; LEARNED=no
if [ -f "$REC" ]; then
  T="$(sed 's/<!--.*-->//g' "$REC")"
  echo "$T" | grep -qE 'Pipeline \(first deploy\).*https?://[^ |]+/-/pipelines/[0-9]+' && { PIPE=yes; ok "First deploy recorded with its pipeline link"; } \
    || warn "DEPLOYED.md: no pipeline link for the first deploy yet"
  echo "$T" | grep -qE 'https://[a-z0-9]+\.z[0-9]+\.web\.core\.windows\.net' && { SITE=yes; ok "Site URL recorded"; } \
    || warn "DEPLOYED.md: no site URL (https://st....web.core.windows.net) yet"
  echo "$T" | grep -qE 'Pipeline \(second deploy\).*https?://[^ |]+/-/pipelines/[0-9]+' && { SECOND=yes; ok "Second deploy recorded - a change rolled out by merge"; } \
    || warn "DEPLOYED.md: no second deploy yet - change 'message' in a merge request and record that pipeline"
  echo "$T" | grep -qiE 'Destroyed[^|]*\|[[:space:]]*(yes|auto)' && { DESTROYED=yes; ok "Destroyed - the test resource is cleaned up"; } \
    || warn "DEPLOYED.md: not marked destroyed - run cdtest:destroy (or let auto-stop do it) and record it"
  [ "$(echo "$T" | sed -n '/What we learned/,$p' | grep -cE '[A-Za-z]{3,}')" -ge 2 ] && { LEARNED=yes; ok "What we learned - written"; } \
    || warn "DEPLOYED.md: 'What we learned' is empty"
else
  warn "No infra-test/DEPLOYED.md - the record of your deployment"
fi

hdr "Ready to point it at infra/?"
MISS=0
bar() { if [ "$1" = "yes" ]; then echo "  ${C_G}[ HAVE ]${C_0} $2"; else echo "  ${C_R}[ NEED ]${C_0} $2"; MISS=$((MISS+1)); fi; }
R=no; [ "$HAVE_FILES" = yes ] && [ "$INCLUDED" = yes ] && R=yes; bar $R "Pipeline and Terraform in the repo, included"
bar $ON_MAIN "Merged to main through a merge request"
R=no; [ "$PIPE" = yes ] && [ "$SITE" = yes ] && R=yes; bar $R "Deployed by main's pipeline - recorded in DEPLOYED.md"
bar $SECOND "A change rolled out by a second merge"
bar $DESTROYED "Test resource destroyed"
R=no; [ -z "$LEAK" ] && [ -z "$STATE" ] && R=yes; bar $R "No secrets or state in git"
echo
[ "$MISS" -eq 0 ] && echo "  ${C_G}READY${C_0} - the path works. Next: the same pipeline, pointed at your own infra/." || echo "  ${C_Y}NOT YET${C_0} - $MISS item(s) above."

echo
echo "============================================================"
echo " ${C_G}ok: $PASS${C_0}   ${C_Y}warnings: $WARN${C_0}   ${C_R}failed: $FAIL${C_0}"
echo "============================================================"
if [ "$FAIL" -gt 0 ]; then echo " Something required is missing. Fix the [FAIL] lines and run again."; exit 1; fi
[ "$WARN" -gt 0 ] && echo " Nothing is broken. Work through the warnings - they are the rest of the lab."
exit 0
