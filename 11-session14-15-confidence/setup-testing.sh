#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  setup-testing.sh  -  Sessions 14 and 15, layer 5: automate the confidence - a test strategy with
#                       measurable thresholds, a growing suite, API, performance and end-to-end checks,
#                       and a pipeline that deploys and decides (macOS / Linux / WSL)
#
#  What it does, once per group:
#    1. Adds the four layer-5 Claude Code commands and the templates
#    2. Adds ci/confidence.py (the scorecard) and ci/confidence.yml for your stack, included in
#       .gitlab-ci.yml; makes sure the stages check, test, deploy and verify exist
#    3. Starts tests/api/ (a Postman collection) and tests/perf/smoke.js (a k6 smoke) - if you have none
#    4. Starts specs/design/test-strategy.md from the template - /test-strategy fills it
#    5. Keeps reports and pipeline-only files out of git (.gitignore); adds the layer-5 section to CLAUDE.md
#    6. Commits all of it as one commit, on a branch if you are on main
#
#  The deploy half stays OFF (CONFIDENCE_DEPLOY: "off") until Session 15. Never overwrites your files.
#
#  USAGE
#    chmod +x setup-testing.sh            # first time only
#    ./setup-testing.sh <path-to-case-repo> [python|node|java] [app-folder]
#
#  A PowerShell twin (setup-testing.ps1) exists for native Windows.
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
REPO="${1:-}"; STACK="${2:-}"; APP="${3:-}"
[ -n "$REPO" ] || { echo "Usage: ./setup-testing.sh <path-to-case-repo> [python|node|java] [app-folder]"; exit 1; }
[ -d "$REPO" ] || { bad "Path not found: $REPO"; exit 1; }
REPO="$(cd "$REPO" && pwd)"
CI="$REPO/.gitlab-ci.yml"

echo "============================================================"
echo " Junior SWAT Labs - Sessions 14-15 - set up layer 5"
echo " $REPO"
echo "============================================================"

hdr "Before we start"
[ -d "$REPO/.git" ] || { bad "Not a git repository."; exit 1; }
[ -f "$REPO/constitution.md" ] || { bad "No constitution.md - layers 1 to 4 come first"; exit 1; }
if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  bad "You have uncommitted changes. Commit or stash them first, so this step is one clean commit."; exit 1
fi
git -C "$REPO" rev-parse -q --verify refs/tags/L4-behaviour >/dev/null && ok "Tag L4-behaviour found - layer 5 starts from it" \
  || warn "No tag L4-behaviour - tag what you have (git tag L4-behaviour && git push --tags), log the rest as debt"
CUR="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
DEF="$(git -C "$REPO" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"; DEF="${DEF:-main}"
if [ "$CUR" = "$DEF" ]; then
  git -C "$REPO" pull --ff-only --quiet 2>/dev/null && ok "$DEF is up to date" || warn "Could not pull $DEF - carrying on"
  if git -C "$REPO" rev-parse -q --verify refs/heads/setup/layer-5 >/dev/null; then git -C "$REPO" switch --quiet setup/layer-5; warn "Branch setup/layer-5 already existed - switched to it"
  else git -C "$REPO" switch --quiet -c setup/layer-5 && ok "Created branch setup/layer-5 - main is protected"; fi
  CUR=setup/layer-5
else ok "Working on branch $CUR"; fi
[ -f "$REPO/ci/quality.yml" ] && ok "Session 13 quality gates found (ci/quality.yml)" || warn "No ci/quality.yml - Session 13's quality gates come first (10-session13-quality)"

add() {   # add <source> <destination> - never overwrites
  if [ -e "$2" ]; then ok "${2#$REPO/} already exists - left alone"
  else mkdir -p "$(dirname "$2")" && cp "$1" "$2" && ok "${2#$REPO/} added"; fi
}

hdr "1 · Commands and templates"
mkdir -p "$REPO/.claude/commands"
N=0; for c in "$HERE"/claude-commands/*.md; do cp "$c" "$REPO/.claude/commands/"; N=$((N+1)); done
ok "$N layer-5 commands added to .claude/commands/"
for t in test-strategy.md ai-tests-review.md defect-analysis.md; do add "$HERE/templates/$t" "$REPO/templates/$t"; done

hdr "2 · Your stack"
if [ -z "$STACK" ] || [ -z "$APP" ]; then
  FOUND="$(cd "$REPO" && find . -maxdepth 3 \( -name node_modules -o -name .git -o -name .claude -o -name specs -o -name target -o -name .venv -o -name tests \) -prune -o \
           -type f \( -name pom.xml -o -name package.json -o -name pyproject.toml -o -name requirements.txt \) -print 2>/dev/null | sort)"
  pick() { echo "$FOUND" | grep -E "/$1\$" | awk -F/ '{print NF, $0}' | sort -n | head -1 | cut -d' ' -f2-; }
  for cand in "java:pom.xml" "node:package.json" "python:pyproject.toml" "python:requirements.txt"; do
    s="${cand%%:*}"; f="${cand#*:}"; [ -n "$STACK" ] && [ "$STACK" != "$s" ] && continue
    hit="$(pick "$f")"; [ -n "$hit" ] || continue
    STACK="$s"; [ -n "$APP" ] || APP="$(dirname "$hit" | sed 's#^\./##; s#^\.$#.#')"; break
  done
fi
APP="${APP:-.}"
case "$STACK" in
  python|node|java) ok "Stack: $STACK, app folder: $APP" ;;
  *) bad "Could not tell your stack. Run again: ./setup-testing.sh \"$REPO\" <python|node|java> <app-folder>"; exit 1 ;;
esac
[ -f "$REPO/$APP/Dockerfile" ] && ok "$APP/Dockerfile found - build:image will use it" || warn "No $APP/Dockerfile - Session 12 wrote one; build:image needs it in Session 15"
[ -d "$REPO/infra" ] && ok "infra/ found - deploy:test will apply it" || warn "No infra/ - Session 12's Terraform; deploy:test needs it in Session 15"

hdr "3 · The confidence pipeline"
mkdir -p "$REPO/ci"
add "$HERE/ci/confidence.py" "$REPO/ci/confidence.py"
if [ -e "$REPO/ci/confidence.yml" ]; then ok "ci/confidence.yml already exists - left alone"
else
  sed "s#APP_DIR: \".\" #APP_DIR: \"$APP\" #" "$HERE/ci/confidence-$STACK.yml" > "$REPO/ci/confidence.yml"
  ok "ci/confidence.yml added - $STACK, app folder $APP. Deploy half OFF until Session 15"
fi
F=ci/confidence.yml
if [ ! -f "$CI" ]; then printf 'include:\n  - local: %s\n' "$F" > "$CI"; warn ".gitlab-ci.yml created - you had none"
elif grep -q "$F" "$CI"; then ok "$F is already included"
elif grep -qE '^include:[[:space:]]*\[.*\][[:space:]]*$' "$CI"; then
  sed -i.bak -E "s#^include:[[:space:]]*\[(.*)\][[:space:]]*\$#include: [\1, { local: $F }]#" "$CI" && rm -f "$CI.bak"; ok "$F added to your include: list"
elif grep -qE '^include:[[:space:]]*$' "$CI"; then
  awk -v f="$F" '{ print } /^include:[[:space:]]*$/ && !d { print "  - local: " f; d=1 }' "$CI" > "$CI.tmp" && mv "$CI.tmp" "$CI"; ok "$F added to your include: list"
elif grep -qE '^include:' "$CI"; then warn "Your include: is in a form this script does not edit. Add yourself:   - local: $F"
else printf '\ninclude:\n  - local: %s\n' "$F" >> "$CI" && ok "$F included"; fi

# stages - the order matters: build, check, test, deploy, verify. Missing ones go in their place.
WANT="build check test deploy verify"
if ! grep -qE '^stages:' "$CI"; then
  awk 'NR==1 && /^#/ { print; next } !d { print "stages: [build, check, test, deploy, verify]\n"; d=1 } { print }' "$CI" > "$CI.tmp" && mv "$CI.tmp" "$CI"
  ok "stages: [build, check, test, deploy, verify] added"
else
  if grep -qE '^stages:[[:space:]]*\[.*\]' "$CI"; then
    LINE="$(grep -E '^stages:' "$CI" | head -1)"
    HAVE="$(echo "$LINE" | sed -E 's/^stages:[[:space:]]*\[(.*)\].*/\1/' | tr ',' ' ' | xargs)"
  else
    HAVE="$(awk '/^stages:/{f=1;next} f && /^[[:space:]]*-/{sub(/^[[:space:]]*-[[:space:]]*/,""); sub(/[[:space:]]*(#.*)?$/,""); print; next} f{exit}' "$CI" | xargs)"
  fi
  NEW="$HAVE"
  for s in $WANT; do
    case " $NEW " in *" $s "*) continue ;; esac
    [ "$s" = build ] && continue                          # only needed when there is no list at all
    PREV=""; for w in $WANT; do [ "$w" = "$s" ] && break; case " $NEW " in *" $w "*) PREV="$w" ;; esac; done
    if [ -z "$PREV" ]; then NEW="$s $NEW"
    else NEW="$(echo " $NEW " | sed "s/ $PREV / $PREV $s /" | xargs)"; fi
  done
  if [ "$NEW" != "$HAVE" ]; then
    if grep -qE '^stages:[[:space:]]*\[.*\]' "$CI"; then
      NEWLINE="stages: [$(echo "$NEW" | sed 's/ /, /g')]"
      awk -v old="$LINE" -v new="$NEWLINE" '$0 == old && !d { print new; d=1; next } { print }' "$CI" > "$CI.tmp" && mv "$CI.tmp" "$CI"
    else
      awk -v list="$NEW" '/^stages:/ { print; n=split(list,a," "); for(i=1;i<=n;i++) print "  - " a[i]; f=1; next } f && /^[[:space:]]*-/ { next } { f=0; print }' "$CI" > "$CI.tmp" && mv "$CI.tmp" "$CI"
    fi
    ok "stages: now  $NEW"
  else ok "stages: already has check, test, deploy, verify"; fi
fi

hdr "4 · Test suites and the strategy"
add "$HERE/starters/api/local.postman_environment.json" "$REPO/tests/api/local.postman_environment.json"
if ls "$REPO"/tests/api/*.postman_collection.json >/dev/null 2>&1; then ok "tests/api/ already has a collection - left alone"
else add "$HERE/starters/api/starter.postman_collection.json" "$REPO/tests/api/$(basename "$REPO").postman_collection.json"; fi
add "$HERE/starters/perf/smoke.js" "$REPO/tests/perf/smoke.js"
mkdir -p "$REPO/.claude/test-starters"; cp -r "$HERE/starters/e2e" "$REPO/.claude/test-starters/" && ok ".claude/test-starters/e2e - a Playwright starter, if you have a web UI (README, Session 15)"
add "$HERE/templates/test-strategy.md" "$REPO/specs/design/test-strategy.md"
mkdir -p "$REPO/reviews"; add "$HERE/templates/ai-tests-review.md" "$REPO/reviews/ai-tests.md"

hdr "5 · .gitignore and CLAUDE.md"
GI="$REPO/.gitignore"; touch "$GI"
[ -s "$GI" ] && [ -n "$(tail -c1 "$GI")" ] && echo >> "$GI"
for line in 'newman*.xml' 'k6-summary.json' 'confidence.md' 'confidence.json' 'health.json' 'app.log' 'ci_backend_override.tf' \
            'tests/e2e/node_modules/' 'tests/e2e/test-results/' 'tests/e2e/playwright-report/' 'e2e.xml'; do
  grep -qxF "$line" "$GI" || echo "$line" >> "$GI"
done
ok ".gitignore keeps reports and pipeline-only files out of git"
if [ -f "$REPO/CLAUDE.md" ] && grep -q '^## Layer 5' "$REPO/CLAUDE.md"; then ok "CLAUDE.md already has the layer-5 section"
else cat "$HERE/templates/CLAUDE-layer5.md" >> "$REPO/CLAUDE.md" && ok "Layer-5 section added to CLAUDE.md"; fi

hdr "6 · One commit"
git -C "$REPO" add -A
if git -C "$REPO" diff --cached --quiet; then ok "Nothing new to commit"
else
  git -C "$REPO" commit -q -m "setup: layer 5 - confidence pipeline, test starters, strategy template, testing commands" \
    && ok "Committed on $CUR" || { bad "Commit failed - see the message above"; exit 1; }
fi

echo
echo "Next - step by step in $HERE/WORKSHOP-S14.md:"
echo "  2. Make your code measurable: test reports, /health with version, APP_START - $HERE/stacks.md"
echo "  3. Measure today:  python3 ci/confidence.py --when merge   (from the repo root, after your tests ran)"
echo "  4. /test-strategy specs/<slice>    - risks, layers, thresholds from what you measured"
echo "  5. Draw the whole pipeline: section 6 of the strategy, then ci/confidence.yml - real and (planned) jobs"
echo "  6. Push:  git -C \"$REPO\" push -u origin $CUR -o merge_request.create -o merge_request.target=$DEF"
echo "  Check as you go:  ./check-testing.sh \"$REPO\""
