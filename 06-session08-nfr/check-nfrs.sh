#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-nfrs.sh  -  Session 8 NFR register and constraints  (macOS/Linux/WSL)
#
#  Checks that every requirement can be verified and has an owner, and that
#  your design does not quietly depend on something the platform policy denies.
#
#  USAGE
#    chmod +x check-nfrs.sh     # first time only
#    ./check-nfrs.sh [path-to-case-repo]     (default: current directory)
#
#  A PowerShell twin (check-nfrs.ps1) exists for native Windows.
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
REG="$REPO/specs/nfr-register.md"
CON="$REPO/specs/constraints.md"

echo "============================================================"
echo " Junior SWAT Labs - Session 8 - requirements and constraints"
echo " $REPO"
echo "============================================================"

[ -d "$REPO" ] || { bad "Path not found: $REPO"; exit 1; }

rows() { grep -E '^\|' "$1" 2>/dev/null | grep -viE '^\|[[:space:]]*(Family|Constraint|-+)'; }

hdr "The register"
if [ -f "$REG" ]; then ok "specs/nfr-register.md present"
else bad "specs/nfr-register.md missing"; fi

if [ -f "$REG" ]; then
  R=$(rows "$REG" | awk -F'|' 'NF>=7 {gsub(/^[ \t]+|[ \t]+$/,"",$3); if ($3!="") print}' | wc -l | tr -d ' ')
  if   [ "${R:-0}" -ge 1 ]; then ok "$R requirement(s) written"
  else bad "No requirements in the register"; fi

  FULL=$(rows "$REG" | awk -F'|' 'NF>=7 {e=0; for(i=2;i<=7;i++){gsub(/^[ \t]+|[ \t]+$/,"",$i); if($i=="") e=1} if(!e) print}' | wc -l | tr -d ' ')
  if   [ "${FULL:-0}" -ge 1 ]; then ok "$FULL line(s) fill all six columns"
  else warn "No line fills all six columns - an incomplete line is not ready"; fi

  OWN=$(rows "$REG" | awk -F'|' 'NF>=7 {gsub(/^[ \t]+|[ \t]+$/,"",$5); if ($5!="") print $5}' | grep -vciE '^(the business|business|it|team|ops|everyone)$' || true)
  VAGUE=$(rows "$REG" | awk -F'|' 'NF>=7 {gsub(/^[ \t]+|[ \t]+$/,"",$5); print tolower($5)}' | grep -cE '^(the business|business|it|team|ops|everyone)$' || true)
  if [ "${OWN:-0}" -ge 1 ]; then ok "$OWN threshold(s) have a named owner"
  else warn "No named owner anywhere - a threshold with no owner is folklore"; fi
  [ "${VAGUE:-0}" -eq 0 ] || warn "$VAGUE owner cell(s) say \"the business\" or similar - that is not a person"

  CHK=$(rows "$REG" | awk -F'|' 'NF>=7 {gsub(/^[ \t]+|[ \t]+$/,"",$6); if ($6!="") print}' | wc -l | tr -d ' ')
  if [ "${CHK:-0}" -ge 1 ]; then ok "$CHK line(s) say how they would be checked"
  else warn "Nothing says how it would be checked - an unverifiable requirement is a wish with a table row"; fi

  if grep -qiE '\|[^|]*\b(fast|quick|secure|reliable|scalable|user.friendly|seamless)\b[^|]*\|' "$REG"; then
    warn "An adjective is doing the work of a threshold somewhere in the register"
  fi
  if rows "$REG" | grep -qiE '^\|[[:space:]]*operability'; then ok "Operability has a line"
  else warn "No operability line - the family production cares about most"; fi
fi

hdr "Constraints"
if [ -f "$CON" ]; then
  ok "specs/constraints.md present"
  PLAT=$(awk '/platform/{f=1} f' "$CON" | grep -E '^\|' | awk -F'|' 'NF>=4 {gsub(/^[ \t]+|[ \t]+$/,"",$3); if ($3!="" && $3!~/^-+$/ && $3!="What it means for us") print}' | wc -l | tr -d ' ')
  if [ "${PLAT:-0}" -ge 1 ]; then ok "$PLAT platform constraint(s) have a consequence written against them"
  else warn "The platform table has no consequences filled in - the policy has not met your design yet"; fi
  grep -qiE 'east us|canada central' "$CON" && ok "The region constraint is recorded" || warn "The region constraint is not recorded"
else bad "specs/constraints.md missing"; fi

hdr "Does the design fit the platform policy?"
# constraints.md is where denied services are *supposed* to be named, so it is excluded
SPECS=$(find "$REPO/specs" -type f \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' -o -name '*.json' \) ! -name 'constraints.md' -exec cat {} + 2>/dev/null || true)
HITS=0
for svc in "azure sql" "sql managed instance" "postgres" "postgresql" "synapse" "data factory" "databricks" "machine learning"; do
  if printf '%s\n' "$SPECS" | grep -qi "$svc"; then warn "Your specs mention \"$svc\" - the lab policy denies it"; HITS=$((HITS+1)); fi
done
for rgn in "central india" "centralindia" "south india" "west india"; do
  if printf '%s\n' "$SPECS" | grep -qi "$rgn"; then warn "Your specs mention \"$rgn\" - that region is blocked"; HITS=$((HITS+1)); fi
done
[ "$HITS" -eq 0 ] && ok "Nothing in your specs names a denied service or a blocked region"

hdr "Did it get shorter?"
if [ -d "$REPO/.git" ] && [ -f "$REG" ]; then
  N=$(git -C "$REPO" rev-list --count HEAD -- specs/nfr-register.md 2>/dev/null || echo 0)
  if [ "${N:-0}" -ge 2 ]; then
    NOW=$(rows "$REG" | wc -l | tr -d ' ')
    PREV=$(git -C "$REPO" show HEAD~1:specs/nfr-register.md 2>/dev/null | grep -E '^\|' | grep -viE '^\|[[:space:]]*(Family|-+)' | wc -l | tr -d ' ')
    if   [ "${NOW:-0}" -lt "${PREV:-0}" ]; then ok "The register got shorter after the attack ($PREV to $NOW lines)"
    elif [ "${NOW:-0}" -eq "${PREV:-0}" ]; then warn "The register is the same length - did anything survive being argued with?"
    else warn "The register grew ($PREV to $NOW lines) - something has gone wrong"; fi
  else warn "Only $N commit(s) on the register - commit before the attack and after it"; fi
else warn "Not a git repository"; fi

summary
