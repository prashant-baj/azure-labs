#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-integration.sh  -  Session 6 integration decisions  (macOS/Linux/WSL)
#
#  Checks that each seam has a decision somebody could disagree with, and that
#  the rejected options were written down. It checks discipline, not taste.
#
#  USAGE
#    chmod +x check-integration.sh     # first time only
#    ./check-integration.sh [path-to-case-repo]     (default: current directory)
#
#  A PowerShell twin (check-integration.ps1) exists for native Windows.
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
summary() {
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
}

REPO="${1:-.}"
DEC="$REPO/specs/integration-decisions.md"

echo "============================================================"
echo " Junior SWAT Labs - Session 6 - integration decisions"
echo " $REPO"
echo "============================================================"

[ -d "$REPO" ] || { bad "Path not found: $REPO"; exit 1; }

hdr "The file"
if [ -f "$DEC" ]; then ok "specs/integration-decisions.md present"
else bad "specs/integration-decisions.md missing - copy templates/integration-decision.md into it"; summary; fi

hdr "Decision records"
RECORDS=$(grep -c '^## The seam' "$DEC" || true)
if   [ "${RECORDS:-0}" -ge 2 ]; then ok "$RECORDS seams have a decision record"
elif [ "${RECORDS:-0}" -eq 1 ]; then warn "Only one seam recorded - most designs have more than one edge"
else bad "No decision records found (expected '## The seam' per record)"; fi

if grep -qE '<our component>|<their system|<a person or a team|<the reason, not the preference>' "$DEC"; then
  bad "Template placeholders are still in the file"
else ok "Template placeholders replaced"; fi

hdr "Ownership"
OWNERS=$(awk '/^## Who owns the other side/{getline; while ($0 ~ /^[[:space:]]*$/) getline; print}' "$DEC" | grep -vcE '^<|^$' || true)
if [ "${OWNERS:-0}" -ge 1 ]; then ok "$OWNERS seam(s) name an owner for the other side"
else warn "No owner named for any seam - that is a finding, not a detail"; fi
if grep -qiE '^\s*(IT|IT team|the business)\s*$' "$DEC"; then
  warn "\"IT\" or \"the business\" is listed as an owner - neither is a person"
fi

hdr "Options and rejections"
REJ=$(awk '/^## Rejected, and why/{f=1;next} /^## /{f=0} f' "$DEC" | grep -E '^[-*][[:space:]]+' | grep -vcE '<Option>|<why it lost' || true)
if   [ "${REJ:-0}" -ge 2 ]; then ok "$REJ rejected options recorded with a reason"
elif [ "${REJ:-0}" -eq 1 ]; then warn "Only one rejected option written down across all seams"
else bad "No rejected options - a record with no rejections is a preference, not a decision"; fi

hdr "Shape of each conversation"
SHAPES=$(grep -ioE '^\*\*Shape:\*\*[[:space:]]*(request|event|file)' "$DEC" | grep -oiE '(request|event|file)$' | tr 'A-Z' 'a-z' | sort -u | wc -l | tr -d ' ')
CHOSEN=$(grep -cioE '^\*\*Shape:\*\*[[:space:]]*(request|event|file)' "$DEC" || true)
if [ "${CHOSEN:-0}" -eq 0 ]; then warn "No seam states its chosen shape - add '**Shape:** request | event | file'"
elif [ "${SHAPES:-0}" -le 1 ] && [ "${RECORDS:-0}" -ge 3 ]; then
  warn "Every seam chose the same shape - fashion, or did each one genuinely need it?"
else ok "Shapes recorded across $CHOSEN seam(s)"; fi

hdr "How you find out it changed"
CHG=$(awk '/^## How we find out it changed/{f=1;next} /^## /{f=0} f' "$DEC" | grep -vE '^\s*$' | grep -vcE '^<' || true)
if [ "${CHG:-0}" -ge 1 ]; then ok "$CHG seam(s) say how a change would be noticed"
else warn "Nobody has said how you would find out the other side changed - the classic outage"; fi

hdr "The context diagram"
DIA=$(ls "$REPO"/specs/diagrams/* 2>/dev/null | wc -l | tr -d ' ')
MER=$(grep -rl '```mermaid' "$REPO/specs" 2>/dev/null | wc -l | tr -d ' ')
if   [ "${DIA:-0}" -ge 1 ]; then ok "specs/diagrams holds $DIA file(s)"
elif [ "${MER:-0}" -ge 1 ]; then ok "A diagram is embedded in specs/"
else warn "No context diagram found - a photograph of a whiteboard in specs/diagrams counts"; fi

hdr "Commit discipline"
if [ -d "$REPO/.git" ]; then
  N=$(git -C "$REPO" rev-list --count HEAD -- specs/integration-decisions.md 2>/dev/null || echo 0)
  if [ "${N:-0}" -ge 1 ]; then ok "$N commit(s) touch the decisions file"
  else warn "The decisions file has not been committed yet"; fi
else warn "Not a git repository"; fi

summary
