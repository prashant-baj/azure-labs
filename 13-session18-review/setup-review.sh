#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  setup-review.sh  -  Session 18, layer 7: the Engineering Excellence Review - a production and operations
#                      readiness checklist, a runbook, a review board's findings and the client's feedback,
#                      decided and the top ones fixed (macOS / Linux / WSL)
#
#  What it does, once per group:
#    1. Adds the four layer-7 Claude Code commands and the templates
#    2. Starts specs/design/readiness.md - production and operations readiness - with your case's two lines
#    3. Starts ops/runbook.md, specs/review/findings.md and specs/review/feedback.md
#    4. Adds the layer-7 section to CLAUDE.md
#    5. Commits all of it as one commit, on a branch if you are on main
#
#  Never overwrites your files.
#
#  USAGE
#    chmod +x setup-review.sh             # first time only
#    ./setup-review.sh <path-to-case-repo>
#
#  A PowerShell twin (setup-review.ps1) exists for native Windows.
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
[ -n "$REPO" ] || { echo "Usage: ./setup-review.sh <path-to-case-repo>"; exit 1; }
[ -d "$REPO" ] || { bad "Path not found: $REPO"; exit 1; }
REPO="$(cd "$REPO" && pwd)"

echo "============================================================"
echo " Junior SWAT Labs - Session 18 - set up layer 7"
echo " $REPO"
echo "============================================================"

hdr "Before we start"
[ -d "$REPO/.git" ] || { bad "Not a git repository."; exit 1; }
if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  bad "You have uncommitted changes. Commit or stash them first, so this step is one clean commit."; exit 1
fi
git -C "$REPO" rev-parse -q --verify refs/tags/L6-production >/dev/null && ok "Tag L6-production found - the review starts from it" \
  || warn "No tag L6-production - review what you have; what is missing becomes a finding, not a reason to skip the board"
[ -f "$REPO/specs/design/threat-model.md" ] && ok "Threat model found" || warn "No specs/design/threat-model.md - the board will ask (PR-08)"
[ -f "$REPO/specs/design/observability.md" ] && ok "Observability spec found" || warn "No specs/design/observability.md - the board will ask (PR-15)"
CUR="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
DEF="$(git -C "$REPO" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"; DEF="${DEF:-main}"
if [ "$CUR" = "$DEF" ]; then
  git -C "$REPO" pull --ff-only --quiet 2>/dev/null && ok "$DEF is up to date" || warn "Could not pull $DEF - carrying on"
  if git -C "$REPO" rev-parse -q --verify refs/heads/setup/layer-7 >/dev/null; then git -C "$REPO" switch --quiet setup/layer-7; warn "Branch setup/layer-7 already existed - switched to it"
  else git -C "$REPO" switch --quiet -c setup/layer-7 && ok "Created branch setup/layer-7 - main is protected"; fi
  CUR=setup/layer-7
else ok "Working on branch $CUR"; fi

add() {   # add <source> <destination> - never overwrites
  if [ -e "$2" ]; then ok "${2#$REPO/} already exists - left alone"
  else mkdir -p "$(dirname "$2")" && cp "$1" "$2" && ok "${2#$REPO/} added"; fi
}

hdr "1 - Commands and templates"
mkdir -p "$REPO/.claude/commands"
N=0; for c in "$HERE"/claude-commands/*.md; do cp "$c" "$REPO/.claude/commands/"; N=$((N+1)); done
ok "$N layer-7 commands added to .claude/commands/"
for t in readiness.md runbook.md findings.md feedback.md; do add "$HERE/templates/$t" "$REPO/templates/$t"; done

hdr "2 - The readiness checklist"
RD="$REPO/specs/design/readiness.md"
ORIGIN="$(git -C "$REPO" remote get-url origin 2>/dev/null || echo "$REPO")"
LETTER="$(echo "$ORIGIN" | grep -oE 'case-[a-e]' | tail -1)"
LINES="$HERE/templates/case-lines/${LETTER:-none}.md"
if [ -e "$RD" ]; then ok "specs/design/readiness.md already exists - left alone"
else
  mkdir -p "$(dirname "$RD")"
  if [ -f "$LINES" ]; then
    awk -v f="$LINES" '/^<!-- case lines -->/ { while ((getline l < f) > 0) print l; next } { print }' "$HERE/templates/readiness.md" > "$RD"
    ok "specs/design/readiness.md added - 17 production and 12 operations lines, and two lines for $LETTER"
  else
    cp "$HERE/templates/readiness.md" "$RD"
    warn "specs/design/readiness.md added - could not tell your case from the repo name: copy your two lines from <lab>/templates/case-lines/case-<letter>.md into section 3"
  fi
fi

hdr "3 - Runbook, findings, feedback"
add "$HERE/templates/runbook.md" "$REPO/ops/runbook.md"
add "$HERE/templates/findings.md" "$REPO/specs/review/findings.md"
add "$HERE/templates/feedback.md" "$REPO/specs/review/feedback.md"

hdr "4 - CLAUDE.md"
if [ -f "$REPO/CLAUDE.md" ] && grep -q '^## Layer 7' "$REPO/CLAUDE.md"; then ok "CLAUDE.md already has the layer-7 section"
else cat "$HERE/templates/CLAUDE-layer7.md" >> "$REPO/CLAUDE.md" && ok "Layer-7 section added to CLAUDE.md"; fi

hdr "5 - One commit"
git -C "$REPO" add -A
if git -C "$REPO" diff --cached --quiet; then ok "Nothing new to commit"
else
  git -C "$REPO" commit -q -m "setup: layer 7 - readiness checklist, runbook, review findings and feedback templates, review commands" \
    && ok "Committed on $CUR" || { bad "Commit failed - see the message above"; exit 1; }
fi

echo
echo "Next - step by step in $HERE/WORKSHOP-S18.md:"
echo "  2. /readiness-check specs/<slice>  and  /runbook   - every line with evidence, or an honest gap"
echo "  3. /board-brief                    - three minutes: running slice, two numbers, scorecard, your own gaps"
echo "  4. The board - $HERE/board/rotation.md and board/rubric.md"
echo "  Check as you go:  ./check-review.sh \"$REPO\""
