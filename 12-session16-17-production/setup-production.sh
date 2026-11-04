#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  setup-production.sh  -  Sessions 16 and 17, layer 6: secure, observable, ready for production -
#                          a threat model with tested controls, a scan of the running service,
#                          Application Insights with one business and one technical signal, alerts,
#                          a drill and a rollback (macOS / Linux / WSL)
#
#  What it does, once per group:
#    1. Adds the four layer-6 Claude Code commands and the templates
#    2. Adds ci/production.yml (verify:dast, verify:observability, the drill, rollback), included in
#       .gitlab-ci.yml; brings ci/confidence.py up to date if you never changed it
#    3. Adds infra/secrets.tf (Session 16) and infra/observability.tf.s17 (Session 17 renames it to .tf)
#    4. Starts specs/design/threat-model.md and specs/design/observability.md from the templates, and
#       copies your case's notes (case-notes/) to specs/design/threat-notes.md
#    5. Keeps scan and telemetry reports out of git (.gitignore); adds the layer-6 section to CLAUDE.md
#    6. Commits all of it as one commit, on a branch if you are on main
#
#  OBSERVABILITY stays "off" until Session 17. Never overwrites your files.
#
#  USAGE
#    chmod +x setup-production.sh         # first time only
#    ./setup-production.sh <path-to-case-repo>
#
#  A PowerShell twin (setup-production.ps1) exists for native Windows.
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
[ -n "$REPO" ] || { echo "Usage: ./setup-production.sh <path-to-case-repo>"; exit 1; }
[ -d "$REPO" ] || { bad "Path not found: $REPO"; exit 1; }
REPO="$(cd "$REPO" && pwd)"
CI="$REPO/.gitlab-ci.yml"

echo "============================================================"
echo " Junior SWAT Labs - Sessions 16-17 - set up layer 6"
echo " $REPO"
echo "============================================================"

hdr "Before we start"
[ -d "$REPO/.git" ] || { bad "Not a git repository."; exit 1; }
[ -f "$REPO/ci/confidence.yml" ] || { bad "No ci/confidence.yml - layer 5 comes first (11-session14-15-confidence)"; exit 1; }
if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  bad "You have uncommitted changes. Commit or stash them first, so this step is one clean commit."; exit 1
fi
git -C "$REPO" rev-parse -q --verify refs/tags/L5-tested >/dev/null && ok "Tag L5-tested found - layer 6 starts from it" \
  || warn "No tag L5-tested - tag what you have (git tag L5-tested && git push --tags), log the rest as debt"
grep -qE '^[[:space:]]*CONFIDENCE_DEPLOY:[[:space:]]*"on"' "$REPO/ci/confidence.yml" && ok "CONFIDENCE_DEPLOY is on - main deploys and verifies" \
  || warn "CONFIDENCE_DEPLOY is not on - verify:dast needs a deployed service (Session 15, step 5)"
CUR="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
DEF="$(git -C "$REPO" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"; DEF="${DEF:-main}"
if [ "$CUR" = "$DEF" ]; then
  git -C "$REPO" pull --ff-only --quiet 2>/dev/null && ok "$DEF is up to date" || warn "Could not pull $DEF - carrying on"
  if git -C "$REPO" rev-parse -q --verify refs/heads/setup/layer-6 >/dev/null; then git -C "$REPO" switch --quiet setup/layer-6; warn "Branch setup/layer-6 already existed - switched to it"
  else git -C "$REPO" switch --quiet -c setup/layer-6 && ok "Created branch setup/layer-6 - main is protected"; fi
  CUR=setup/layer-6
else ok "Working on branch $CUR"; fi

add() {   # add <source> <destination> - never overwrites
  if [ -e "$2" ]; then ok "${2#$REPO/} already exists - left alone"
  else mkdir -p "$(dirname "$2")" && cp "$1" "$2" && ok "${2#$REPO/} added"; fi
}
sum() {   # md5 of the file with Windows line endings removed - the same on every checkout
  if command -v md5sum >/dev/null 2>&1; then tr -d '\r' < "$1" | md5sum | cut -d' ' -f1; else tr -d '\r' < "$1" | md5 -q; fi
}

hdr "1 - Commands and templates"
mkdir -p "$REPO/.claude/commands"
N=0; for c in "$HERE"/claude-commands/*.md; do cp "$c" "$REPO/.claude/commands/"; N=$((N+1)); done
ok "$N layer-6 commands added to .claude/commands/"
for t in threat-model.md observability.md; do add "$HERE/templates/$t" "$REPO/templates/$t"; done

hdr "2 - The production checks in the pipeline"
add "$HERE/ci/production.yml" "$REPO/ci/production.yml"
NEWSUM="$(sum "$HERE/ci/confidence.py")"
if [ ! -f "$REPO/ci/confidence.py" ]; then cp "$HERE/ci/confidence.py" "$REPO/ci/confidence.py"; ok "ci/confidence.py added"
else
  HAVE="$(sum "$REPO/ci/confidence.py")"
  case "$HAVE" in
    "$NEWSUM") ok "ci/confidence.py already reads the scan and the telemetry" ;;
    659101c48dba65b9c889c2298640d515|3279dafc12ea73a720f4e1be7640db0d)
      cp "$HERE/ci/confidence.py" "$REPO/ci/confidence.py"; ok "ci/confidence.py updated - it now reads zap.json and obs.json too" ;;
    *) cp "$HERE/ci/confidence.py" "$REPO/ci/confidence.py.new"
       warn "You changed ci/confidence.py - the new one is ci/confidence.py.new. Merge its dast.* and obs.* measures in, then delete it" ;;
  esac
fi
F=ci/production.yml
if [ ! -f "$CI" ]; then printf 'include:\n  - local: %s\n' "$F" > "$CI"; warn ".gitlab-ci.yml created - you had none"
elif grep -q "$F" "$CI"; then ok "$F is already included"
elif grep -qE '^include:[[:space:]]*\[.*\][[:space:]]*$' "$CI"; then
  sed -i.bak -E "s#^include:[[:space:]]*\[(.*)\][[:space:]]*\$#include: [\1, { local: $F }]#" "$CI" && rm -f "$CI.bak"; ok "$F added to your include: list"
elif grep -qE '^include:[[:space:]]*$' "$CI"; then
  awk -v f="$F" '{ print } /^include:[[:space:]]*$/ && !d { print "  - local: " f; d=1 }' "$CI" > "$CI.tmp" && mv "$CI.tmp" "$CI"; ok "$F added to your include: list"
elif grep -qE '^include:' "$CI"; then warn "Your include: is in a form this script does not edit. Add yourself:   - local: $F"
else printf '\ninclude:\n  - local: %s\n' "$F" >> "$CI" && ok "$F included"; fi
grep -qE '^stages:.*verify|^[[:space:]]*-[[:space:]]*verify[[:space:]]*$' "$CI" && ok "stage verify found" \
  || warn "No verify stage in .gitlab-ci.yml - setup-testing adds it; add verify after deploy"

hdr "3 - Terraform: secrets now, observability in Session 17"
if [ -d "$REPO/infra" ]; then
  add "$HERE/infra-additions/secrets.tf" "$REPO/infra/secrets.tf"
  if [ -e "$REPO/infra/observability.tf" ]; then ok "infra/observability.tf already exists - left alone"
  else add "$HERE/infra-additions/observability.tf" "$REPO/infra/observability.tf.s17"; fi
  grep -q 'app_secret_names' "$REPO/infra/main.tf" 2>/dev/null && ok "main.tf already hands the secrets to the Container App" \
    || warn "main.tf does not use the secrets yet - paste $HERE/infra-additions/container-app-secrets.snippet.tf (WORKSHOP-S16.md, step 4)"
else warn "No infra/ - Session 12's Terraform; the secrets and the observability stack live there"; fi

hdr "4 - The threat model and the observability spec"
add "$HERE/templates/threat-model.md" "$REPO/specs/design/threat-model.md"
add "$HERE/templates/observability.md" "$REPO/specs/design/observability.md"
ORIGIN="$(git -C "$REPO" remote get-url origin 2>/dev/null || echo "$REPO")"
LETTER="$(echo "$ORIGIN" | grep -oE 'case-[a-e]' | tail -1)"
NOTE="$(ls "$HERE"/case-notes/"${LETTER:-none}"-*.md 2>/dev/null | head -1)"
if [ -n "$NOTE" ]; then ok "Your case: $(basename "$NOTE" .md) - its notes are checks for step 2"; add "$NOTE" "$REPO/specs/design/threat-notes.md"
else warn "Could not tell your case from the repo name - copy yours: cp <lab>/case-notes/case-<letter>-*.md specs/design/threat-notes.md"; fi

hdr "5 - .gitignore and CLAUDE.md"
GI="$REPO/.gitignore"; touch "$GI"
[ -s "$GI" ] && [ -n "$(tail -c1 "$GI")" ] && echo >> "$GI"
for line in 'zap.json' 'zap.html' 'obs.json' 'drill-k6.json' '*.tfvars' '.env'; do
  grep -qxF "$line" "$GI" || echo "$line" >> "$GI"
done
ok ".gitignore keeps scan and telemetry reports, .tfvars and .env out of git"
if [ -f "$REPO/CLAUDE.md" ] && grep -q '^## Layer 6' "$REPO/CLAUDE.md"; then ok "CLAUDE.md already has the layer-6 section"
else cat "$HERE/templates/CLAUDE-layer6.md" >> "$REPO/CLAUDE.md" && ok "Layer-6 section added to CLAUDE.md"; fi

hdr "6 - One commit"
git -C "$REPO" add -A
if git -C "$REPO" diff --cached --quiet; then ok "Nothing new to commit"
else
  git -C "$REPO" commit -q -m "setup: layer 6 - production checks, secrets and observability Terraform, threat model and observability templates" \
    && ok "Committed on $CUR" || { bad "Commit failed - see the message above"; exit 1; }
fi

echo
echo "Next - step by step in $HERE/WORKSHOP-S16.md:"
echo "  2. /threat-model specs/<slice>     - what could go wrong, STRIDE by STRIDE; try T-01 on your own service"
echo "  3. Controls, red test first: the key, the headers, escaping - $HERE/stacks.md, sections 1 to 4"
echo "  4. The secret's journey: masked APP_API_KEY in GitLab, infra/secrets.tf, the snippet into main.tf"
echo "  5. Push, merge - verify:dast scans the deployed service; set the dast.* rows from what it found"
echo "  Check as you go:  ./check-production.sh \"$REPO\""
