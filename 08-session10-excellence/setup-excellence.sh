#!/usr/bin/env bash
# =============================================================================
#  FDE Program 2026 - Labs
#  setup-excellence.sh  -  Session 10: add the layer 2 templates, commands and
#                           merge request checklist to your case repository
#                           (macOS / Linux / WSL)
#
#  What it does, once per group:
#    1. Adds templates: engineering rules, plan section 12, review, tech debt
#    2. Adds specs/design/tech-debt.md and the GitLab merge request checklist
#    3. Adds the five Session 10 Claude Code commands and the prompts file
#    4. Adds the Session 10 section to CLAUDE.md
#    5. Commits all of it as one commit
#
#  It never deletes anything, and never overwrites a file you have written.
#
#  USAGE
#    chmod +x setup-excellence.sh           # first time only
#    ./setup-excellence.sh <path-to-case-repo>
#
#  A PowerShell twin (setup-excellence.ps1) exists for native Windows.
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
[ -n "$REPO" ] || { echo "Usage: ./setup-excellence.sh <path-to-case-repo>"; exit 1; }
[ -d "$REPO" ] || { bad "Path not found: $REPO"; exit 1; }
REPO="$(cd "$REPO" && pwd)"

echo "============================================================"
echo " Junior SWAT Labs - Session 10 - set up layer 2"
echo " $REPO"
echo "============================================================"

hdr "Before we start"
[ -d "$REPO/.git" ] || { bad "Not a git repository."; exit 1; }
[ -f "$REPO/constitution.md" ] || { bad "No constitution.md - finish the Session 9 minimum bar first (07-session09-spec/check-spec)"; exit 1; }
if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  bad "You have uncommitted changes. Commit them first, so this step is one clean commit:"
  echo "      git -C \"$REPO\" add -A && git -C \"$REPO\" commit -m \"wip: before Session 10\""
  exit 1
fi
ok "Clean git repository with a constitution"

add() {   # add <source> <destination> - never overwrites
  if [ -e "$2" ]; then ok "${2#$REPO/} already exists - left alone"
  else mkdir -p "$(dirname "$2")" && cp "$1" "$2" && ok "${2#$REPO/} added"; fi
}

hdr "1 · Templates"
for t in engineering-rules plan-section-12 review tech-debt; do add "$HERE/templates/$t.md" "$REPO/templates/$t.md"; done

hdr "2 · Debt register and the merge request checklist"
add "$HERE/templates/tech-debt.md" "$REPO/specs/design/tech-debt.md"
add "$HERE/templates/merge_request_template.md" "$REPO/.gitlab/merge_request_templates/Default.md"

hdr "3 · Claude Code commands and prompts"
mkdir -p "$REPO/.claude/commands" "$REPO/prompts"
N=0; for c in "$HERE"/claude-commands/*.md; do cp "$c" "$REPO/.claude/commands/"; N=$((N+1)); done
ok "$N commands added to .claude/commands/"
cp "$HERE/prompts/10-excellence.md" "$REPO/prompts/" && ok "prompts/10-excellence.md added"

hdr "4 · CLAUDE.md"
if [ -f "$REPO/CLAUDE.md" ] && grep -q '^## Session 10' "$REPO/CLAUDE.md"; then ok "CLAUDE.md already has the Session 10 section"
else cat "$HERE/templates/CLAUDE-session10.md" >> "$REPO/CLAUDE.md" && ok "Session 10 section added to CLAUDE.md"; fi

hdr "5 · One commit"
git -C "$REPO" add -A
if git -C "$REPO" diff --cached --quiet; then ok "Nothing new to commit"
else
  git -C "$REPO" commit -q -m "setup: Session 10 - engineering rules, review and refactor commands, MR checklist" \
    && ok "Committed: setup: Session 10 ..." || { bad "Commit failed - see the message above"; exit 1; }
fi

echo
echo "Next:"
echo "  1. git -C \"$REPO\" push"
echo "  2. In Claude Code, from the repository:  /spec-engineering-rules"
echo "  3. Check as you go:  ./check-excellence.sh \"$REPO\""
