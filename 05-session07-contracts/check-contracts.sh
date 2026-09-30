#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-contracts.sh  -  Session 7 contracts and ADRs  (macOS / Linux / WSL)
#
#  Checks the things a drafted contract always gets wrong, and that your ADRs
#  record what the decision cost as well as what it gained.
#
#  USAGE
#    chmod +x check-contracts.sh     # first time only
#    ./check-contracts.sh [path-to-case-repo]     (default: current directory)
#
#  A PowerShell twin (check-contracts.ps1) exists for native Windows.
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
CDIR="$REPO/specs/contracts"
ADIR="$REPO/specs/adr"

echo "============================================================"
echo " Junior SWAT Labs - Session 7 - contracts and decision records"
echo " $REPO"
echo "============================================================"

[ -d "$REPO" ] || { bad "Path not found: $REPO"; exit 1; }

hdr "Contracts"
if [ -d "$CDIR" ]; then
  NC=$(find "$CDIR" -type f \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' -o -name '*.json' \) | wc -l | tr -d ' ')
  if [ "${NC:-0}" -ge 1 ]; then ok "$NC contract file(s) in specs/contracts"
  else bad "specs/contracts is empty"; fi
else bad "specs/contracts missing"; NC=0; fi

ALL=$(cat "$CDIR"/* 2>/dev/null || true)

if [ "${NC:-0}" -ge 1 ]; then
  # errors
  ERRROWS=$(printf '%s\n' "$ALL" | awk '/^## 2\. Errors/{f=1;next} /^## /{f=0} f' | grep -E '^\|' | awk -F'|' 'NF>=3 {gsub(/^[ \t]+|[ \t]+$/,"",$2); if ($2!="" && $2!~/^-+$/ && $2!="What went wrong") print}' | wc -l | tr -d ' ')
  ERRCODES=$(printf '%s\n' "$ALL" | grep -cE '\b(4[0-9]{2}|5[0-9]{2})\b' || true)
  if   [ "${ERRROWS:-0}" -ge 2 ] || [ "${ERRCODES:-0}" -ge 2 ]; then ok "Error cases described"
  elif [ "${ERRROWS:-0}" -eq 1 ] || [ "${ERRCODES:-0}" -eq 1 ]; then warn "Only one error case - a draft always gives you exactly one"
  else bad "No error cases - this is the first thing a draft gets wrong"; fi

  # timing, size, duplicates, versioning
  for pair in "Timing:timing" "Size:size" "Duplicates:duplicate" "Changing:version"; do
    HEAD_="${pair%%:*}"; WORD="${pair##*:}"
    HIT=$(printf '%s\n' "$ALL" | awk -v h="$HEAD_" 'BEGIN{IGNORECASE=1} $0 ~ "^## .*" h {f=1;next} /^## /{f=0} f' | grep -vE '^\s*$' | grep -vcE '^<|^-\s*$' || true)
    ALT=$(printf '%s\n' "$ALL" | grep -ciE "$WORD" || true)
    if   [ "${HIT:-0}" -ge 1 ]; then ok "$HEAD_ section filled in"
    elif [ "${ALT:-0}" -ge 1 ]; then warn "$HEAD_ is mentioned but the section is empty"
    else warn "$HEAD_ not covered - drafts leave this out unless asked"; fi
  done

  if printf '%s\n' "$ALL" | grep -qiE 'inferred|assumed'; then
    ok "The draft marked what it inferred, and the marks are still visible"
  else
    warn "Nothing is marked as inferred - either it was asked, or the marks were deleted with the evidence"
  fi
fi

hdr "Architecture decision records"
if [ -d "$ADIR" ]; then
  NA=$(find "$ADIR" -type f -name '*.md' | wc -l | tr -d ' ')
  if   [ "${NA:-0}" -ge 2 ]; then ok "$NA ADRs written"
  elif [ "${NA:-0}" -eq 1 ]; then warn "Only one ADR - two were asked for"
  else bad "specs/adr is empty"; fi
  for f in "$ADIR"/*.md; do
    [ -f "$f" ] || continue
    B=$(basename "$f")
    MISS=""
    for h in Context Decision Alternatives Consequences; do
      grep -qiE "^## $h" "$f" || MISS="$MISS $h"
    done
    if [ -n "$MISS" ]; then warn "$B is missing:$MISS"; else ok "$B has all four sections"; fi
    ALTS=$(awk '/^## Alternatives/{f=1;next} /^## /{f=0} f' "$f" | grep -E '^[-*][[:space:]]' | grep -vcE '<Option>|<why it lost' || true)
    [ "${ALTS:-0}" -ge 2 ] || warn "$B lists fewer than two alternatives"
    BADLINE=$(awk '/^## Consequences/{f=1;next} /^## /{f=0} f' "$f" | grep -iE '^\*\*Bad:\*\*' | sed 's/^\*\*Bad:\*\*//' | grep -vcE '^\s*$|^\s*<' || true)
    [ "${BADLINE:-0}" -ge 1 ] || warn "$B has no bad consequences - that is marketing, not a record"
  done
else bad "specs/adr missing"; fi

hdr "Commit discipline"
if [ -d "$REPO/.git" ]; then
  N=$(git -C "$REPO" rev-list --count HEAD -- specs/contracts 2>/dev/null || echo 0)
  if   [ "${N:-0}" -ge 2 ]; then ok "$N commits touch the contracts - the draft was corrected"
  elif [ "${N:-0}" -eq 1 ]; then warn "One commit only - was the draft accepted unchanged?"
  else warn "Contracts not committed yet"; fi
else warn "Not a git repository"; fi

summary
