#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  setup-quality.sh  -  Session 13, layer 4: quality gates in your workspace and in the pipeline;
#                       stories, executable scenarios tagged with IDs, the rule built test-first
#                       (macOS / Linux / WSL)
#
#  What it does, once per group:
#    1. Adds the seven layer-4 Claude Code commands and the templates
#    2. Finds your stack, keeps a runnable BDD starter for it in .claude/bdd-starter/ (the commands read it)
#    3. The baseline pipeline: ci/quality.yml (lint, complexity, secrets, SAST, dependencies, IaC) and
#       ci/scenarios.yml for your stack, both included in .gitlab-ci.yml; the stages check and test
#    4. Creates specs/<your slice>/features/ - the scenarios live next to the spec
#    5. Keeps local scan output out of git (.gitignore)
#    6. Adds the layer-4 section to CLAUDE.md
#    7. Commits all of it as one commit, on a branch if you are on main
#
#  It never deletes anything, and never overwrites a file you have written. It does not touch your
#  build files (pyproject.toml, package.json, pom.xml) - stacks/<stack>/README.md says what to add.
#
#  USAGE
#    chmod +x setup-quality.sh            # first time only
#    ./setup-quality.sh <path-to-case-repo> [python|node|java] [app-folder]
#    (stack and app folder are found for you; give them only if it guesses wrong)
#
#  A PowerShell twin (setup-quality.ps1) exists for native Windows.
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
[ -n "$REPO" ] || { echo "Usage: ./setup-quality.sh <path-to-case-repo> [python|node|java] [app-folder]"; exit 1; }
[ -d "$REPO" ] || { bad "Path not found: $REPO"; exit 1; }
REPO="$(cd "$REPO" && pwd)"
CI="$REPO/.gitlab-ci.yml"

echo "============================================================"
echo " Junior SWAT Labs - Session 13 - set up layer 4"
echo " $REPO"
echo "============================================================"

hdr "Before we start"
[ -d "$REPO/.git" ] || { bad "Not a git repository."; exit 1; }
[ -f "$REPO/constitution.md" ] || { bad "No constitution.md - layers 1 to 3 come first"; exit 1; }
if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  bad "You have uncommitted changes. Commit or stash them first, so this step is one clean commit."
  exit 1
fi
git -C "$REPO" rev-parse -q --verify refs/tags/L3-working >/dev/null && ok "Tag L3-working found - layer 4 starts from it" \
  || warn "No tag L3-working - tag what works now (git tag L3-working && git push --tags), log the rest as debt"
CUR="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
DEF="$(git -C "$REPO" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"; DEF="${DEF:-main}"
if [ "$CUR" = "$DEF" ]; then
  git -C "$REPO" pull --ff-only --quiet 2>/dev/null && ok "$DEF is up to date" || warn "Could not pull $DEF - carrying on"
  if git -C "$REPO" rev-parse -q --verify refs/heads/setup/layer-4 >/dev/null; then git -C "$REPO" switch --quiet setup/layer-4; warn "Branch setup/layer-4 already existed - switched to it"
  else git -C "$REPO" switch --quiet -c setup/layer-4 && ok "Created branch setup/layer-4 - main is protected"; fi
  CUR=setup/layer-4
else ok "Working on branch $CUR"; fi
SLICE="$(find "$REPO/specs" -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null | sort | tail -1)"
[ -n "$SLICE" ] && ok "Slice: specs/$(basename "$SLICE")" || { bad "No slice folder specs/NNN-<name>/ - layer 1 comes first"; exit 1; }

add() {   # add <source> <destination> - never overwrites
  if [ -e "$2" ]; then ok "${2#$REPO/} already exists - left alone"
  else mkdir -p "$(dirname "$2")" && cp "$1" "$2" && ok "${2#$REPO/} added"; fi
}

hdr "1 · Commands and templates"
mkdir -p "$REPO/.claude/commands"
N=0; for c in "$HERE"/claude-commands/*.md; do cp "$c" "$REPO/.claude/commands/"; N=$((N+1)); done
ok "$N layer-4 commands added to .claude/commands/"
for t in stories.md example-map.md scenario.feature tdd-log.md quality-gates.md; do add "$HERE/templates/$t" "$REPO/templates/$t"; done

hdr "2 · Your stack"
if [ -z "$STACK" ] || [ -z "$APP" ]; then
  FOUND="$(cd "$REPO" && find . -maxdepth 3 \( -name node_modules -o -name .git -o -name .claude -o -name specs -o -name target -o -name .venv \) -prune -o \
           -type f \( -name pom.xml -o -name package.json -o -name pyproject.toml -o -name requirements.txt \) -print 2>/dev/null | sort)"
  pick() { echo "$FOUND" | grep -E "/$1\$" | awk -F/ '{print NF, $0}' | sort -n | head -1 | cut -d' ' -f2-; }
  for cand in "java:pom.xml" "node:package.json" "python:pyproject.toml" "python:requirements.txt"; do
    s="${cand%%:*}"; f="${cand#*:}"; [ -n "$STACK" ] && [ "$STACK" != "$s" ] && continue
    hit="$(pick "$f")"; [ -n "$hit" ] || continue
    STACK="$s"; [ -n "$APP" ] || APP="$(dirname "$hit" | sed 's#^\./##; s#^\.$#.#')"; break
  done
  KINDS="$(echo "$FOUND" | sed -nE 's#.*/(pom\.xml|package\.json|pyproject\.toml|requirements\.txt)$#\1#p' | sed 's/pom.xml/java/; s/package.json/node/; s/pyproject.toml/python/; s/requirements.txt/python/' | sort -u | tr '\n' ' ')"
  [ "$(echo "$KINDS" | wc -w)" -gt 1 ] && warn "Build files for more than one stack ($KINDS) - chose $STACK. Wrong? Run again: ./setup-quality.sh \"$REPO\" <python|node|java> <app-folder>"
fi
APP="${APP:-.}"
case "$STACK" in
  python|node|java) ok "Stack: $STACK, app folder: $APP" ;;
  *) warn "Could not tell your stack - no pom.xml, package.json, pyproject.toml or requirements.txt. Run again with it: ./setup-quality.sh \"$REPO\" <python|node|java> <app-folder>"; STACK="" ;;
esac
if [ -n "$STACK" ]; then
  mkdir -p "$REPO/.claude/bdd-starter"
  ( cd "$HERE/stacks/$STACK" && find . -type f ! -path './node_modules/*' ! -path './target/*' ) | while read -r f; do
    mkdir -p "$REPO/.claude/bdd-starter/$(dirname "$f")"; cp "$HERE/stacks/$STACK/$f" "$REPO/.claude/bdd-starter/$f"
  done
  ok ".claude/bdd-starter/ - a runnable $STACK example the commands copy the wiring from"
fi

hdr "3 · The baseline pipeline - quality gates and scenarios"
include_ci() {   # include_ci ci/<file>.yml - adds it to .gitlab-ci.yml in whatever include: form you have
  local F="$1"
  if [ ! -f "$CI" ]; then printf 'include:\n  - local: %s\n' "$F" > "$CI"; warn ".gitlab-ci.yml created - you had none; add your test job too"
  elif grep -q "$F" "$CI"; then ok "$F is already included"
  elif grep -qE '^include:[[:space:]]*\[.*\][[:space:]]*$' "$CI"; then
    sed -i.bak -E "s#^include:[[:space:]]*\[(.*)\][[:space:]]*\$#include: [\1, { local: $F }]#" "$CI" && rm -f "$CI.bak"; ok "$F added to your include: list"
  elif grep -qE '^include:[[:space:]]*$' "$CI"; then
    awk -v f="$F" '{ print } /^include:[[:space:]]*$/ && !d { print "  - local: " f; d=1 }' "$CI" > "$CI.tmp" && mv "$CI.tmp" "$CI"; ok "$F added to your include: list"
  elif grep -qE '^include:' "$CI"; then warn "Your include: is in a form this script does not edit. Add yourself:   - local: $F"
  else printf '\ninclude:\n  - local: %s\n' "$F" >> "$CI" && ok "$F included"; fi
}
if [ -n "$STACK" ]; then
  mkdir -p "$REPO/ci"
  if [ -e "$REPO/ci/quality.yml" ]; then ok "ci/quality.yml already exists - left alone"
  else
    sed "s#QA_APP_DIR: \".\" #QA_APP_DIR: \"$APP\" #" "$HERE/ci/quality-$STACK.yml" > "$REPO/ci/quality.yml"
    ok "ci/quality.yml added - lint, complexity, secrets, SAST, dependencies, IaC for $STACK"
  fi
  if [ -e "$REPO/ci/scenarios.yml" ]; then ok "ci/scenarios.yml already exists - left alone"
  else
    sed "s#APP_DIR: \".\" #APP_DIR: \"$APP\" #" "$HERE/ci/scenarios-$STACK.yml" > "$REPO/ci/scenarios.yml"
    ok "ci/scenarios.yml added - the $STACK scenarios job, app folder $APP"
  fi
  include_ci ci/quality.yml
  include_ci ci/scenarios.yml
  # stages: the gates need `check` before `test`. No stages: list means GitLab's defaults - no `check`.
  if ! grep -qE '^stages:' "$CI"; then
    awk 'NR==1 && /^#/ { print; next } !d { print "stages: [build, check, test, deploy]\n"; d=1 } { print }' "$CI" > "$CI.tmp" && mv "$CI.tmp" "$CI"
    ok "stages: [build, check, test, deploy] added - GitLab's defaults have no 'check'"
  elif grep -qE '^stages:[[:space:]]*\[.*\]' "$CI"; then
    LINE="$(grep -E '^stages:' "$CI" | head -1)"; NEW="$LINE"
    echo "$NEW" | grep -qE '[[,[:space:]]test[],[:space:]]' || NEW="$(echo "$NEW" | sed -E 's/\][[:space:]]*(#.*)?$/, test]/')"
    echo "$NEW" | grep -qE '[[,[:space:]]check[],[:space:]]' || NEW="$(echo "$NEW" | sed -E 's/^stages:[[:space:]]*\[/stages: [check, /')"
    if [ "$NEW" != "$LINE" ]; then awk -v old="$LINE" -v new="$NEW" '$0 == old && !d { print new; d=1; next } { print }' "$CI" > "$CI.tmp" && mv "$CI.tmp" "$CI"; ok "stages: now  ${NEW#stages: }"
    else ok "stages: has check and test"; fi
  else
    BLOCK="$(awk '/^stages:/{f=1;next} f && /^[^[:space:]#]/{f=0} f' "$CI")"
    if ! echo "$BLOCK" | grep -qE '^[[:space:]]*-[[:space:]]*check[[:space:]]*$'; then
      awk '/^stages:/ && !d { print; print "  - check"; d=1; next } { print }' "$CI" > "$CI.tmp" && mv "$CI.tmp" "$CI"; ok "stage check added first in stages:"
    fi
    if ! echo "$BLOCK" | grep -qE '^[[:space:]]*-[[:space:]]*test[[:space:]]*$'; then
      awk '/^stages:/{f=1; print; next} f && /^[[:space:]]*-/ {print; next} f && !d { print "  - test"; d=1; f=0 } { print } END { if (f && !d) print "  - test" }' "$CI" > "$CI.tmp" && mv "$CI.tmp" "$CI"; ok "stage test added to stages:"
    fi
    ok "stages: has check and test"
  fi
  for j in lint secrets; do
    grep -qE "^$j:" "$CI" && warn "Your .gitlab-ci.yml has the Session 10 job '$j:' - qa:$j replaces it. Delete '$j:' in this merge request"
  done
fi

hdr "4 · Scenarios live with the spec"
mkdir -p "$SLICE/features"
if [ -z "$(ls -A "$SLICE/features" 2>/dev/null)" ]; then
  printf '# Scenarios for %s\n\nOne `.feature` file per story, written with `/spec-scenarios`. Every scenario tagged with the IDs it\nproves (`@FR-0nn`, `@RULE-0nn`). Start from `templates/scenario.feature`.\n' "$(basename "$SLICE")" > "$SLICE/features/README.md"
  ok "specs/$(basename "$SLICE")/features/ created"
else ok "specs/$(basename "$SLICE")/features/ already has files"; fi

hdr "5 · .gitignore - local scan output stays local"
GI="$REPO/.gitignore"; touch "$GI"
[ -s "$GI" ] && [ -n "$(tail -c1 "$GI")" ] && echo >> "$GI"
for line in '.quality/' 'gl-code-quality.json' 'gl-sast-report.json' 'scenarios.xml'; do grep -qxF "$line" "$GI" || echo "$line" >> "$GI"; done
ok ".gitignore keeps .quality/ and the scan reports out of git"

hdr "6 · CLAUDE.md"
if [ -f "$REPO/CLAUDE.md" ] && grep -q '^## Layer 4' "$REPO/CLAUDE.md"; then ok "CLAUDE.md already has the layer-4 section"
else cat "$HERE/templates/CLAUDE-layer4.md" >> "$REPO/CLAUDE.md" && ok "Layer-4 section added to CLAUDE.md"; fi

hdr "7 · One commit"
git -C "$REPO" add -A
if git -C "$REPO" diff --cached --quiet; then ok "Nothing new to commit"
else
  git -C "$REPO" commit -q -m "setup: layer 4 - quality gates and scenarios in the pipeline; stories, scenarios, TDD and quality commands" \
    && ok "Committed on $CUR" || { bad "Commit failed - see the message above"; exit 1; }
fi

echo
echo "Next:"
echo "  1. Wire the runner into your build: $HERE/stacks/${STACK:-<stack>}/README.md  ('Wire it into your repo')"
echo "  2. Push and open the merge request:  git -C \"$REPO\" push -u origin $CUR -o merge_request.create -o merge_request.target=$DEF"
echo "  3. Scan locally:  ./quality-local.sh \"$REPO\"   then /quality-gates and /triage-findings (README, Part B)"
echo "  4. Then the behaviour: /example-map, /spec-stories, /spec-scenarios, /tdd-cycle"
echo "  5. Check as you go:  ./check-quality.sh \"$REPO\""
