#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-spec-repo.sh  -  Session 5 solution definition check  (macOS/Linux/WSL)
#
#  Checks that a group's case repository is in a state the next three sessions
#  can build on. It checks structure and discipline, never the quality of your
#  thinking - that is what the debrief is for.
#
#  USAGE
#    chmod +x check-spec-repo.sh    # first time only
#    ./check-spec-repo.sh [path-to-case-repo]     (default: current directory)
#
#  Exit code is non-zero if any REQUIRED check fails.
#  A PowerShell twin (check-spec-repo.ps1) exists for native Windows.
# =============================================================================

set -uo pipefail

if [ -t 1 ]; then
  C_G=$'\033[0;32m'; C_R=$'\033[0;31m'; C_Y=$'\033[0;33m'; C_B=$'\033[0;36m'; C_0=$'\033[0m'
else C_G=""; C_R=""; C_Y=""; C_B=""; C_0=""; fi
PASS=0; WARN=0; FAIL=0
ok()   { echo "  ${C_G}[ OK ]${C_0} $1"; PASS=$((PASS+1)); }
warn() { echo "  ${C_Y}[WARN]${C_0} $1"; WARN=$((WARN+1)); }
bad()  { echo "  ${C_R}[FAIL]${C_0} $1"; FAIL=$((FAIL+1)); }
hdr()  { echo; echo "${C_B}==> $1${C_0}"; }

REPO="${1:-.}"
SPEC="$REPO/specs/solution-definition.md"

echo "============================================================"
echo " Junior SWAT Labs - Session 5 - solution definition check"
echo " $REPO"
echo "============================================================"

# --- Structure ------------------------------------------------------------
hdr "Repository structure"

[ -d "$REPO" ] || { bad "Path not found: $REPO"; exit 1; }

for d in docs specs templates prompts; do
  if [ -d "$REPO/$d" ]; then ok "$d/ present"; else bad "$d/ missing"; fi
done
if [ -f "$REPO/CLAUDE.md" ]; then ok "CLAUDE.md present"; else bad "CLAUDE.md missing"; fi
if [ -f "$SPEC" ]; then ok "specs/solution-definition.md present"; else bad "specs/solution-definition.md missing"; fi

if [ -d "$REPO/.git" ]; then ok "It is a git repository"; else bad "Not a git repository - run new-case-repo first"; fi

# Module 1 artefacts
DOCCOUNT=$(find "$REPO/docs" -type f \( -name '*.md' -o -name '*.txt' -o -name '*.docx' -o -name '*.pdf' \) ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')
if [ "${DOCCOUNT:-0}" -ge 3 ]; then ok "docs/ holds $DOCCOUNT files"
elif [ "${DOCCOUNT:-0}" -gt 0 ]; then warn "docs/ holds only $DOCCOUNT file(s) - four Module 1 artefacts were expected"
else warn "docs/ is empty - paste in your Module 1 artefacts"; fi

[ -f "$SPEC" ] || { echo; echo "Cannot check the definition itself. Stopping."; exit 1; }

# --- The definition -------------------------------------------------------
hdr "Solution definition"

if grep -qE '<case name>|<One paragraph|<Three to five|<names>|<date>' "$SPEC"; then
  bad "Template placeholders are still in the file"
else
  ok "Template placeholders replaced"
fi

# Objectives: numbered list items in section 2
OBJ=$(awk '/^## 2\. Objectives/{f=1;next} /^## /{f=0} f' "$SPEC" | grep -cE '^[0-9]+\.[[:space:]]+[^[:space:]]' || true)
if [ "${OBJ:-0}" -eq 0 ]; then bad "No objectives found in section 2"
elif [ "${OBJ:-0}" -gt 5 ]; then warn "$OBJ objectives - more than five is usually a feature list"
else ok "$OBJ objectives"; fi

# Scope: a Not now entry (third column of a table row, non-empty)
SCOPE=$(awk '/^## 3\. Scope/{f=1;next} /^## /{f=0} f' "$SPEC" | grep -E '^\|' | grep -vE '^\|[[:space:]]*(In scope|-+)' || true)
NOTNOW=$(echo "$SCOPE" | awk -F'|' 'NF>=4 {gsub(/^[ \t]+|[ \t]+$/,"",$4); if ($4 != "") print $4}' | wc -l | tr -d ' ')
if [ "${NOTNOW:-0}" -ge 1 ]; then ok "Something is in the \"Not now\" column"
else warn "\"Not now\" column is empty - the scope conversation has probably not happened yet"; fi

# Out of scope owner
OUTOWNER=$(echo "$SCOPE" | awk -F'|' 'NF>=4 {gsub(/^[ \t]+|[ \t]+$/,"",$3); if ($3 != "") print $3}' | wc -l | tr -d ' ')
if [ "${OUTOWNER:-0}" -ge 1 ]; then ok "Out-of-scope items listed"
else warn "Nothing marked out of scope - is everything really yours?"; fi

# Stories
STORIES=$(grep -E '^[-*][[:space:]]+As an? ' "$SPEC" | grep -vcE '<role>|<what>|<why' || true)
if [ "${STORIES:-0}" -ge 1 ]; then ok "$STORIES story/stories written"; else bad "No stories found"; fi
if grep -qiE '^[-*][[:space:]]+As an? (user|end user)[ ,]' "$SPEC"; then
  warn "A story uses \"as a user\" - name the actual role from your concern sheet"
fi

# Acceptance criteria in EARS form
SHALL=$(grep -cE '\bshall\b' "$SPEC" || true)
if [ "${SHALL:-0}" -ge 2 ]; then ok "$SHALL requirement statements in EARS form"
elif [ "${SHALL:-0}" -eq 1 ]; then warn "Only one EARS statement found"
else bad "No acceptance criteria in EARS form (When ..., the system shall ...)"; fi

if grep -qiE 'user.friendly|seamless|as per discussion|industry standard' "$SPEC"; then
  warn "A phrase that cannot fail is still in the file (user friendly / seamless / as per discussion)"
fi

# Assumptions
ASSUME=$(awk '/^## 7\. Assumptions/{f=1;next} /^## /{f=0} f' "$SPEC" | grep -E '^\|' | awk -F'|' 'NF>=3 {gsub(/^[ \t]+|[ \t]+$/,"",$2); if ($2 != "" && $2 !~ /^-+$/ && $2 != "We are assuming") print}' | wc -l | tr -d ' ')
if [ "${ASSUME:-0}" -ge 1 ]; then ok "$ASSUME assumption(s) recorded"
else warn "Assumptions and open questions is empty - a tidy document is usually a dishonest one"; fi

# --- Glossary -------------------------------------------------------------
hdr "Glossary"
GLOSS=$(awk '/^## Glossary/{f=1;next} /^## /{f=0} f' "$REPO/CLAUDE.md" 2>/dev/null | grep -E '^\|' | awk -F'|' 'NF>=4 {gsub(/^[ \t]+|[ \t]+$/,"",$2); if ($2 != "" && $2 !~ /^-+$/ && $2 != "Term") print}' | wc -l | tr -d ' ')
if [ "${GLOSS:-0}" -ge 1 ]; then ok "$GLOSS term(s) in the glossary"
else warn "Glossary in CLAUDE.md is empty - the assistant will use your words instead of the client's"; fi

# --- Commit discipline ----------------------------------------------------
hdr "Commit discipline"
if [ -d "$REPO/.git" ]; then
  SPECCOMMITS=$(git -C "$REPO" rev-list --count HEAD -- specs/solution-definition.md 2>/dev/null || echo 0)
  if [ "${SPECCOMMITS:-0}" -ge 2 ]; then ok "$SPECCOMMITS commits touch the solution definition (v1 before review, v2 after)"
  elif [ "${SPECCOMMITS:-0}" -eq 1 ]; then warn "Only one commit touches the definition - was v1 committed before the assistant saw it?"
  else warn "The solution definition has not been committed yet"; fi
  if git -C "$REPO" remote -v 2>/dev/null | grep -q .; then ok "A remote is configured"
  else warn "No git remote - add one and push before you leave"; fi
fi

# --- Summary --------------------------------------------------------------
echo
echo "============================================================"
echo " ${C_G}ok: $PASS${C_0}   ${C_Y}warnings: $WARN${C_0}   ${C_R}failed: $FAIL${C_0}"
echo "============================================================"
if [ "$FAIL" -gt 0 ]; then
  echo " Something required is missing. Fix the [FAIL] lines and run again."
  exit 1
fi
if [ "$WARN" -gt 0 ]; then
  echo " Nothing is broken. Read the warnings and decide - they are judgement calls,"
  echo " and at the debrief you will be asked about them."
fi
exit 0
