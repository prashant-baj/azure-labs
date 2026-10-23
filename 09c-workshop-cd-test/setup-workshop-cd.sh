#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  setup-workshop-cd.sh  -  Lab 09c: continuous deployment of a TEST resource from
#                           your workshop project to Azure (macOS / Linux / WSL)
#
#  What it does, once per group (a Maintainer runs it):
#    1. Adds ci/cd-test.yml (the pipeline) and infra-test/ (the Terraform)
#    2. Includes ci/cd-test.yml in .gitlab-ci.yml and makes sure the stages test and deploy exist
#    3. Keeps Terraform's local files out of git (.gitignore)
#    4. Checks the Terraform (fmt + validate) if terraform is installed
#    5. Commits all of it on a branch cd-test - main is protected, so it goes in by merge request
#
#  It never deletes anything, and never overwrites a file you have written.
#
#  USAGE
#    chmod +x setup-workshop-cd.sh          # first time only
#    ./setup-workshop-cd.sh <path-to-your-workshop-repo>
#
#  A PowerShell twin (setup-workshop-cd.ps1) exists for native Windows.
# =============================================================================

set -uo pipefail
if [ -t 1 ]; then
  C_G=$'\033[0;32m'; C_R=$'\033[0;31m'; C_Y=$'\033[0;33m'; C_B=$'\033[0;36m'; C_0=$'\033[0m'
else C_G=""; C_R=""; C_Y=""; C_B=""; C_0=""; fi
ok()   { echo "  ${C_G}[ OK ]${C_0} $1"; }
warn() { echo "  ${C_Y}[WARN]${C_0} $1"; }
bad()  { echo "  ${C_R}[FAIL]${C_0} $1"; }
hdr()  { echo; echo "${C_B}==> $1${C_0}"; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${1:-}"
[ -n "$REPO" ] || { echo "Usage: ./setup-workshop-cd.sh <path-to-your-workshop-repo>"; exit 1; }
[ -d "$REPO" ] || { bad "Path not found: $REPO"; exit 1; }
REPO="$(cd "$REPO" && pwd)"
CI="$REPO/.gitlab-ci.yml"
BRANCH=cd-test

echo "============================================================"
echo " Junior SWAT Labs - 09c - CD of a test resource to Azure"
echo " $REPO"
echo "============================================================"

hdr "Before we start"
[ -d "$REPO/.git" ] || { bad "Not a git repository."; exit 1; }
[ -f "$REPO/constitution.md" ] || warn "No constitution.md - is this your workshop repo? Carrying on"
if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  bad "You have uncommitted changes. Commit or stash them first, so this step is one clean commit."
  exit 1
fi
CUR="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
DEF="$(git -C "$REPO" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"; DEF="${DEF:-main}"
if [ "$CUR" = "$DEF" ]; then
  git -C "$REPO" pull --ff-only --quiet 2>/dev/null && ok "$DEF is up to date with GitLab" || warn "Could not pull $DEF - carrying on with what you have"
  if git -C "$REPO" rev-parse -q --verify "refs/heads/$BRANCH" >/dev/null; then
    git -C "$REPO" switch --quiet "$BRANCH" && warn "Branch $BRANCH already existed - switched to it"
  else
    git -C "$REPO" switch --quiet -c "$BRANCH" && ok "Created branch $BRANCH from $DEF"
  fi
  CUR="$BRANCH"
else
  ok "Working on branch $CUR"
fi

add() {   # add <source> <destination> - never overwrites
  if [ -e "$2" ]; then ok "${2#$REPO/} already exists - left alone"
  else mkdir -p "$(dirname "$2")" && cp "$1" "$2" && ok "${2#$REPO/} added"; fi
}

hdr "1 · The pipeline and the Terraform"
add "$HERE/ci/cd-test.yml" "$REPO/ci/cd-test.yml"
for f in versions.tf variables.tf main.tf outputs.tf site/index.html.tftpl; do add "$HERE/infra-test/$f" "$REPO/infra-test/$f"; done
add "$HERE/templates/DEPLOYED.md" "$REPO/infra-test/DEPLOYED.md"

hdr "2 · .gitlab-ci.yml"
if [ ! -f "$CI" ]; then
  printf '# The group pipeline.\nstages: [test, deploy]\n\ninclude:\n  - local: ci/cd-test.yml\n' > "$CI"
  ok ".gitlab-ci.yml created with the test deployment included"
  warn "You had no pipeline at all - add your lint and test jobs too (08-session10-excellence/ci/)"
else
  if grep -q 'ci/cd-test.yml' "$CI"; then ok "ci/cd-test.yml is already included"
  elif grep -qE '^include:[[:space:]]*\[.*\][[:space:]]*$' "$CI"; then         # include: [{ local: a.yml }]
    sed -i.bak -E 's#^include:[[:space:]]*\[(.*)\][[:space:]]*$#include: [\1, { local: ci/cd-test.yml }]#' "$CI" && rm -f "$CI.bak"
    ok "ci/cd-test.yml added to your include: list"
  elif grep -qE '^include:[[:space:]]*$' "$CI"; then                            # include:\n  - local: a.yml
    awk '{ print } /^include:[[:space:]]*$/ && !d { print "  - local: ci/cd-test.yml"; d=1 }' "$CI" > "$CI.tmp" && mv "$CI.tmp" "$CI"
    ok "ci/cd-test.yml added to your include: list"
  elif grep -qE '^include:' "$CI"; then
    warn "Your include: is written in a form this script does not edit. Add this yourself:   - local: ci/cd-test.yml"
  else
    printf '\ninclude:\n  - local: ci/cd-test.yml\n' >> "$CI" && ok "ci/cd-test.yml included"
  fi

  if ! grep -qE '^stages:' "$CI"; then
    ok "No stages: list - GitLab's default (build, test, deploy) already has test and deploy"
  elif grep -qE '^stages:[[:space:]]*\[.*\]' "$CI"; then                       # stages: [check, test]
    LINE="$(grep -E '^stages:' "$CI" | head -1)"; NEW="$LINE"
    for s in test deploy; do
      echo "$NEW" | grep -qE "[[,[:space:]]$s[],[:space:]]" || NEW="$(echo "$NEW" | sed -E "s/\][[:space:]]*(#.*)?$/, $s]/")"
    done
    if [ "$NEW" != "$LINE" ]; then
      awk -v old="$LINE" -v new="$NEW" '$0 == old && !d { print new; d=1; next } { print }' "$CI" > "$CI.tmp" && mv "$CI.tmp" "$CI"
      ok "stages: now  ${NEW#stages: }"
    else ok "stages: already has test and deploy"; fi
  else                                                                          # stages:\n  - check\n  - test
    for s in test deploy; do
      if awk '/^stages:/{f=1;next} f && /^[^[:space:]#]/{f=0} f' "$CI" | grep -qE "^[[:space:]]*-[[:space:]]*$s[[:space:]]*(#.*)?$"; then continue; fi
      awk -v s="$s" '
        /^stages:/ { print; f=1; next }
        f && /^[[:space:]]*-/ { print; next }
        f { print "  - " s; f=0; added=1 }
        { print }
        END { if (f && !added) print "  - " s }' "$CI" > "$CI.tmp" && mv "$CI.tmp" "$CI"
      ok "stage $s added to stages:"
    done
  fi
fi

hdr "3 · .gitignore - Terraform's local files never go to git"
touch "$REPO/.gitignore"
for p in '.terraform/' '*.tfstate' '*.tfstate.*' '*.tfplan' '*.tfvars' 'cdtest.env'; do
  grep -qxF "$p" "$REPO/.gitignore" || { echo "$p" >> "$REPO/.gitignore"; ok "$p added"; }
done
ok ".gitignore covers Terraform state, plans, tfvars and .terraform/"

hdr "4 · Terraform check"
if command -v terraform >/dev/null; then
  ( cd "$REPO/infra-test" && terraform fmt -check -recursive >/dev/null && terraform init -backend=false -input=false >/dev/null 2>&1 && terraform validate -no-color >/dev/null ) \
    && ok "terraform fmt and validate pass" || warn "terraform fmt/validate reported something - run it in infra-test/ and read it"
else
  warn "terraform not installed here - fine, the pipeline job cdtest:validate does the same check"
fi

hdr "5 · Commit"
git -C "$REPO" add ci/cd-test.yml infra-test .gitlab-ci.yml .gitignore
if git -C "$REPO" diff --cached --quiet; then ok "Nothing new to commit"
else
  git -C "$REPO" commit --quiet -m "ci: deploy a test resource to Azure from main (lab 09c)" && ok "Committed on $CUR"
fi

echo
echo "============================================================"
echo " Next - README step 3:"
echo "   1. Read the diff:   git -C \"$REPO\" show --stat"
echo "   2. Push and open the merge request in one go:"
echo "        git -C \"$REPO\" push -u origin $CUR -o merge_request.create -o merge_request.target=$DEF \\"
echo "          -o merge_request.title=\"CD test: deploy a test resource to Azure\""
echo "   3. Branch pipeline: cdtest:validate must be green. Then review and merge as usual."
echo "   4. On $DEF: watch cdtest:state -> plan -> apply -> verify. Open Operate > Environments > cd-test."
echo "============================================================"
