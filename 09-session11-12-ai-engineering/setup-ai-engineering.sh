#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  setup-ai-engineering.sh  -  Sessions 11 and 12, layer 3: add the AI review
#                               pipeline job, commands and templates
#                               (macOS / Linux / WSL)
#
#  What it does, once per group:
#    1. Adds ci/ai-review.yml, ci/review-mr.md, ci/post-review.mjs
#    2. Creates .gitlab-ci.yml with the AI review included - or adds the include
#    3. Adds the ten layer-3 Claude Code commands, templates, prompts and the Azure lab constraints
#    4. Adds the layer-3 section to CLAUDE.md
#    5. Commits all of it as one commit
#
#  It never deletes anything, and never overwrites a file you have written.
#
#  USAGE
#    chmod +x setup-ai-engineering.sh       # first time only
#    ./setup-ai-engineering.sh <path-to-case-repo>
#
#  A PowerShell twin (setup-ai-engineering.ps1) exists for native Windows.
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
[ -n "$REPO" ] || { echo "Usage: ./setup-ai-engineering.sh <path-to-case-repo>"; exit 1; }
[ -d "$REPO" ] || { bad "Path not found: $REPO"; exit 1; }
REPO="$(cd "$REPO" && pwd)"

echo "============================================================"
echo " Junior SWAT Labs - Sessions 11-12 - set up layer 3"
echo " $REPO"
echo "============================================================"

hdr "Before we start"
[ -d "$REPO/.git" ] || { bad "Not a git repository."; exit 1; }
[ -f "$REPO/constitution.md" ] || { bad "No constitution.md - layers 1 and 2 come first"; exit 1; }
if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  bad "You have uncommitted changes. Commit them first, so this step is one clean commit:"
  echo "      git -C \"$REPO\" add -A && git -C \"$REPO\" commit -m \"wip: before Session 11\""
  exit 1
fi
git -C "$REPO" rev-parse -q --verify refs/tags/L2-design >/dev/null && ok "Tag L2-design found - layer 3 starts from it" \
  || warn "No tag L2-design - layer 2 is not tagged yet. Carry on, and tag what you have"

add() {   # add <source> <destination> - never overwrites
  if [ -e "$2" ]; then ok "${2#$REPO/} already exists - left alone"
  else mkdir -p "$(dirname "$2")" && cp "$1" "$2" && ok "${2#$REPO/} added"; fi
}

hdr "1 · The AI review job"
for f in ai-review.yml review-mr.md post-review.mjs; do add "$HERE/ci/$f" "$REPO/ci/$f"; done

hdr "2 · .gitlab-ci.yml"
CI="$REPO/.gitlab-ci.yml"
if [ ! -f "$CI" ]; then cp "$HERE/templates/gitlab-ci-starter.yml" "$CI" && ok ".gitlab-ci.yml created, with the AI review included"
elif grep -q 'ci/ai-review.yml' "$CI"; then ok ".gitlab-ci.yml already includes the AI review"
elif grep -qE '^include:' "$CI"; then warn ".gitlab-ci.yml already has an include: list - add this line to it yourself:   - local: ci/ai-review.yml"
else printf '\ninclude:\n  - local: ci/ai-review.yml\n' >> "$CI" && ok "AI review included in your existing .gitlab-ci.yml"; fi

hdr "3 · Commands, templates and prompts"
mkdir -p "$REPO/.claude/commands" "$REPO/prompts"
N=0; for c in "$HERE"/claude-commands/*.md; do cp "$c" "$REPO/.claude/commands/"; N=$((N+1)); done
ok "$N commands added to .claude/commands/"
for t in prompt-card validation spec-review; do add "$HERE/templates/$t.md" "$REPO/templates/$t.md"; done
cp "$HERE/prompts/11-12-ai-engineering.md" "$HERE/prompts/spec-enhancement.md" "$REPO/prompts/" && ok "prompts/11-12-ai-engineering.md and prompts/spec-enhancement.md added"
add "$HERE/../lab-constraints.md" "$REPO/specs/design/azure-lab-constraints.md"   # read by /azure-gaps and /azure-terraform
mkdir -p "$REPO/.claude/infra-starter"; for f in "$HERE"/infra-starter/*; do add "$f" "$REPO/.claude/infra-starter/$(basename "$f")"; done   # the known-good Terraform shape /azure-terraform starts from
GI="$REPO/.gitignore"; touch "$GI"
[ -s "$GI" ] && [ -n "$(tail -c1 "$GI")" ] && echo >> "$GI"   # end the last line first
for line in '*.tfstate' '*.tfstate.*' '.terraform/' '*.tfvars' '!*.tfvars.example' '.env' 'ai-review.json' 'ai-review.md' 'ai-review.log'; do
  grep -qxF "$line" "$GI" || echo "$line" >> "$GI"
done
ok ".gitignore keeps Terraform state, .terraform/, *.tfvars, .env and local AI review files out of git"

hdr "4 · CLAUDE.md"
if [ -f "$REPO/CLAUDE.md" ] && grep -q '^## Layer 3' "$REPO/CLAUDE.md"; then ok "CLAUDE.md already has the layer-3 section"
else cat "$HERE/templates/CLAUDE-layer3.md" >> "$REPO/CLAUDE.md" && ok "Layer-3 section added to CLAUDE.md"; fi

hdr "5 · One commit"
git -C "$REPO" add -A
if git -C "$REPO" diff --cached --quiet; then ok "Nothing new to commit"
else
  git -C "$REPO" commit -q -m "setup: layer 3 - AI review in the pipeline, task and validation commands" \
    && ok "Committed: setup: layer 3 ..." || { bad "Commit failed - see the message above"; exit 1; }
fi

echo
echo "Next:"
echo "  1. Push - on a branch if main is protected:  git -C \"$REPO\" switch -c setup/layer-3 && git -C \"$REPO\" push -u origin setup/layer-3"
echo "  2. Add the two masked CI/CD variables (README, Part A) - your group's Maintainer does this"
echo "  3. Check as you go:  ./check-ai-engineering.sh \"$REPO\""
