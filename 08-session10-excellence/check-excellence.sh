#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-excellence.sh  -  Session 10, layer 2: is the code shaped well,
#                          and did the spec change first?   (macOS / Linux / WSL)
#
#  Checks structure, rules, review decisions and git discipline - never whether
#  the design is good. That is what the review and the debrief are for.
#
#  USAGE
#    chmod +x check-excellence.sh            # first time only
#    ./check-excellence.sh [path-to-case-repo] [slice-folder]
#      slice-folder defaults to the highest-numbered specs/NNN-* folder
#
#  Exit code is non-zero only if something required is missing.
#  A PowerShell twin (check-excellence.ps1) exists for native Windows.
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
[ -d "$REPO" ] || { echo "Path not found: $REPO"; exit 1; }
REPO="$(cd "$REPO" && pwd)"
if [ -n "${2:-}" ]; then SLICE="$REPO/${2#./}"; [ -d "$SLICE" ] || SLICE="$REPO/specs/${2}"
else SLICE="$(find "$REPO/specs" -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null | sort | tail -1)"; fi
CONST="$REPO/constitution.md"; SPEC="$SLICE/spec.md"; PLAN="$SLICE/plan.md"
DEBT="$REPO/specs/design/tech-debt.md"

echo "============================================================"
echo " Junior SWAT Labs - Session 10 - layer 2 check"
echo " $REPO"
echo "============================================================"

# Helpers ---------------------------------------------------------------------
section() { awk -v h="$2" 'index($0,h)==1{f=1;next} /^## /{f=0} f' "$1" 2>/dev/null; }
cell()    { awk -F'|' -v n="$1" '{ c=$(n+1); gsub(/^[ \t]+|[ \t]+$/,"",c); print c }'; }
ids()     { grep -oE "\b$2-[0-9]{3}\b" "$1" 2>/dev/null | sort -u; }
# source and test files - everything outside the spec, docs and lab scaffolding
EXCL='/(specs|docs|templates|prompts|\.claude|\.git|\.gitlab|node_modules|target|build|dist|\.venv|venv|__pycache__|examples)/'
srcfiles() { find "$REPO" -type f \( -name '*.py' -o -name '*.java' -o -name '*.kt' -o -name '*.js' -o -name '*.ts' -o -name '*.cs' -o -name '*.go' \) 2>/dev/null | grep -vE "$EXCL"; }
testfiles() { srcfiles | grep -iE '(/tests?/|test_[^/]*$|_test\.[a-z]+$|Tests?\.(java|kt|cs)$|\.(test|spec)\.(js|ts)$)'; }

[ -d "$REPO/.git" ] || { bad "Not a git repository"; exit 1; }
if [ -z "$SLICE" ] || [ ! -f "$SPEC" ]; then bad "No slice spec found (specs/NNN-name/spec.md) - Session 9 comes first"; exit 1; fi
ok "Slice: specs/$(basename "$SLICE")"

# --- 1. The spec changed first ------------------------------------------------
hdr "1 · The spec changed first"
S5=$(section "$CONST" "## 5.")
NE=$(echo "$S5" | grep -E '^\|[[:space:]]*E-[0-9]{3}' | cell 2 | grep -c . || true)
NECHK=$(echo "$S5" | grep -E '^\|[[:space:]]*E-[0-9]{3}' | awk -F'|' '{c=$3; k=$4; gsub(/[ \t]/,"",c); gsub(/[ \t]/,"",k); if (c!="" && k!="") print}' | wc -l | tr -d ' ')
if [ -z "$S5" ]; then bad "constitution.md has no section 5 - engineering rules. Run /spec-engineering-rules"
elif [ "$NE" -lt 3 ]; then warn "Only $NE engineering rule(s) in section 5 - pick five to seven"
else ok "$NE engineering rules in constitution section 5"; fi
if [ "$NE" -gt 0 ]; then
  [ "$NECHK" -eq "$NE" ] && ok "Every engineering rule says how it is checked" \
    || warn "$((NE-NECHK)) rule(s) with no 'Checked by' - a rule nobody checks is a wish"
fi
[ "$NE" -gt 7 ] && warn "$NE engineering rules - will you really check all of them?"

S12=$(section "$PLAN" "## 12.")
COMP=$(echo "$S12" | grep -E '^\|' | grep -vE '^\|[[:space:]]*(Component|-+)[[:space:]]*\|' | awk -F'|' '{c=$2; j=$3; gsub(/[ \t]/,"",c); gsub(/[ \t]/,"",j); if (c!="" && j!="") print}')
NCOMP=$(echo "$COMP" | grep -c . || true)
if [ -z "$S12" ]; then bad "plan.md has no section 12 - components. Run /spec-components"
elif [ "$NCOMP" -lt 2 ]; then warn "Section 12 has $NCOMP component(s) - is the slice really one piece?"
else ok "$NCOMP components in plan section 12"; fi
AND=$(echo "$COMP" | cell 2 | grep -ciE '\band\b' || true)
[ "$NCOMP" -gt 0 ] && { [ "$AND" -eq 0 ] && ok "Every component's job is said without 'and'" \
  || { warn "$AND component(s) need 'and' to say their job - E-002 says split them:"; echo "$COMP" | awk -F'|' 'tolower($3) ~ /(^|[^a-z])and([^a-z]|$)/ {gsub(/^[ \t]+|[ \t]+$/,"",$2); print "           " $2}'; }; }
if [ -z "$S12" ]; then :
elif echo "$S12" | grep -q '^```mermaid' && echo "$S12" | grep -q 'classDiagram'; then
  if echo "$S12" | grep -qE 'class (UseCase|Rule|SomePort|SomeAdapter)\b'; then warn "The class diagram still holds the template's placeholder classes"
  else ok "Class diagram, as code"; fi
else warn "No Mermaid classDiagram in section 12"; fi

# --- 2. The code --------------------------------------------------------------
hdr "2 · The code"
NSRC=$(srcfiles | grep -c . || true); NTST=$(testfiles | grep -c . || true)
if [ "$NSRC" -eq 0 ]; then bad "No code yet - /build-tasks generates the first tasks"
else ok "$NSRC source file(s), of which $NTST test file(s)"; fi
[ "$NSRC" -gt 0 ] && [ "$NTST" -eq 0 ] && warn "No test files - W-003 says the test comes first"
if [ "$NTST" -gt 0 ]; then
  TT=$(testfiles | tr '\n' '\0' | xargs -0 cat 2>/dev/null | tr 'a-z' 'A-Z' | tr '_' '-')
  MISS=""
  for id in $(ids "$SPEC" FR) $(ids "$SPEC" RULE); do echo "$TT" | grep -q "$id" || MISS="$MISS $id"; done
  [ -z "$MISS" ] && ok "Every FR and RULE is named by a test (E-009)" \
    || warn "No test names:$MISS - fine if not built yet; say which at the debrief"
fi
if [ "$NSRC" -gt 0 ]; then
  SECRETS=$(srcfiles | tr '\n' '\0' | xargs -0 grep -nIiE '(password|passwd|secret|api[_-]?key|token)[A-Za-z_]*[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{4,}|-----BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16}' 2>/dev/null | sed "s#$REPO/##" | head -5)
  [ -z "$SECRETS" ] && ok "No obvious secrets in code (the pipeline's gitleaks scan looks deeper)" \
    || { warn "Looks like a secret in code (W-004, E-008):"; echo "$SECRETS" | cut -d: -f1,2 | sed 's/^/           /; s/$/  (value hidden)/'; }
  CATCH=$(srcfiles | tr '\n' '\0' | xargs -0 grep -nE 'except( Exception)?:[[:space:]]*(pass|return None)?[[:space:]]*$|catch[[:space:]]*\([^)]*\)[[:space:]]*\{[[:space:]]*\}' 2>/dev/null | sed "s#$REPO/##" | head -5)
  [ -z "$CATCH" ] && ok "No obvious catch-all that hides errors" \
    || { warn "Catch-all that may hide a failure (E-006, W-006):"; echo "$CATCH" | sed 's/^/           /'; }
fi
[ -f "$REPO/.gitlab-ci.yml" ] && ok ".gitlab-ci.yml present - the rules run as checks" || warn "No .gitlab-ci.yml - a rule in the pipeline beats a rule in a reminder (ci/ has starters)"

# --- 3. Review and debt -------------------------------------------------------
hdr "3 · Review, decisions and debt"
REV=$(ls "$SLICE"/reviews/*review*.md 2>/dev/null | sort | tail -1)
if [ -z "$REV" ]; then bad "No review in specs/$(basename "$SLICE")/reviews/ - run /review-excellence"
else
  ROWS=$(grep -E '^\|[[:space:]]*[0-9]+[[:space:]]*\|' "$REV")
  NF=$(echo "$ROWS" | grep -c . || true)
  ok "Review: ${REV#$REPO/} - $NF finding(s)"
  NORULE=$(echo "$ROWS" | cell 3 | grep -vcE '\b[EW]-[0-9]{3}\b' || true)
  [ "$NF" -gt 0 ] && { [ "$NORULE" -eq 0 ] && ok "Every finding names a rule" || warn "$NORULE finding(s) name no rule - no rule, no finding"; }
  UNDEC=$(echo "$ROWS" | cell 7 | grep -c '^$' || true)
  [ "$NF" -gt 0 ] && { [ "$UNDEC" -eq 0 ] && ok "Every finding decided by the group" || warn "$UNDEC finding(s) not decided yet - fix, debt, or overruled with a reason"; }
  OVR=$(echo "$ROWS" | cell 7 | grep -i 'overrul' | awk '{ if (length($0) < 25) print }' | grep -c . || true)
  [ "$OVR" -gt 0 ] && warn "$OVR overruled finding(s) with no real reason - say why"
  FIX=$(echo "$ROWS" | cell 7 | grep -ci 'fix' || true); DBT=$(echo "$ROWS" | cell 7 | grep -ci 'debt' || true)
  OV=$(echo "$ROWS" | cell 7 | grep -ci 'overrul' || true)
  [ "$NF" -gt 0 ] && echo "         decisions: $FIX fix · $DBT debt · $OV overruled"
fi
if [ ! -f "$DEBT" ]; then warn "No specs/design/tech-debt.md - setup-excellence adds it"
else
  TD=$(grep -E '^\|[[:space:]]*TD-[0-9]{3}' "$DEBT" | awk -F'|' '{w=$3; gsub(/[ \t]/,"",w); if (w!="") print}')
  NTD=$(echo "$TD" | grep -c . || true)
  ok "Debt register: $NTD item(s)"
  NOPAY=$(echo "$TD" | cell 7 | grep -c '^$' || true)
  [ "$NTD" -gt 0 ] && [ "$NOPAY" -gt 0 ] && warn "$NOPAY debt item(s) with no 'Pay back by' - debt with no date is a surprise"
fi

# --- 4. Git discipline --------------------------------------------------------
hdr "4 · Branches, commits and the tag"
CODECOMMITS=$(git -C "$REPO" log --no-merges --format='%h %s' -- '*.py' '*.java' '*.kt' '*.js' '*.ts' '*.cs' '*.go' \
  ':!specs/**' ':!docs/**' ':!templates/**' ':!examples/**' ':!.claude/**' 2>/dev/null)
NCC=$(echo "$CODECOMMITS" | grep -c . || true)
NOT=$(echo "$CODECOMMITS" | grep -vcE 'T[0-9]{3}|refactor:|finding' || true)
if [ "$NCC" -eq 0 ]; then warn "No commits touch code yet"
elif [ "$NOT" -eq 0 ]; then ok "All $NCC code commit(s) name a task or a finding (W-002, E-012)"
else warn "$NOT of $NCC code commit(s) name no task ID - e.g. 'T006: build the matcher (FR-003)'"; fi
NMERGE=$(git -C "$REPO" log --merges --oneline 2>/dev/null | grep -c . || true)
[ "$NMERGE" -ge 1 ] && ok "$NMERGE merge(s) - work arrived through a merge request" \
  || warn "No merges yet - code goes to main through a merge request"
git -C "$REPO" rev-parse -q --verify "refs/tags/L2-design" >/dev/null && ok "Tag L2-design" || warn "No tag L2-design yet - tag main when layer 2 is merged"
PUSHED=no
if git -C "$REPO" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  [ "$(git -C "$REPO" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 1)" -eq 0 ] && PUSHED=yes
fi
[ "$PUSHED" = yes ] && ok "Everything on this branch is pushed" || warn "Not pushed - push before you leave"

# --- Ready for layer 3? ---------------------------------------------------------
hdr "Ready for layer 3? (see BUILD-ROADMAP.md)"
MISS=0
bar() { if [ "$1" = "yes" ]; then echo "  ${C_G}[ HAVE ]${C_0} $2"; else echo "  ${C_R}[ NEED ]${C_0} $2"; MISS=$((MISS+1)); fi; }
R=no; [ "$NE" -ge 3 ] && [ "$NECHK" -eq "$NE" ] && R=yes; bar $R "Engineering rules in the constitution, each with a check"
R=no; [ "$NCOMP" -ge 2 ] && R=yes; bar $R "Components in plan section 12"
R=no; [ "$NSRC" -gt 0 ] && [ "$NTST" -gt 0 ] && R=yes; bar $R "Code for the first tasks, with tests"
R=no; [ -n "$REV" ] && [ "${UNDEC:-1}" -eq 0 ] && R=yes; bar $R "A review with every finding decided"
R=no; git -C "$REPO" rev-parse -q --verify "refs/tags/L2-design" >/dev/null && R=yes; bar $R "Tagged L2-design"
bar $PUSHED "Pushed to your GitLab project"
echo
[ "$MISS" -eq 0 ] && echo "  ${C_G}READY${C_0} - layer 2 is in. Layer 3 builds on it." \
  || echo "  ${C_Y}NOT YET${C_0} - $MISS item(s) above."

echo
echo "============================================================"
echo " ${C_G}ok: $PASS${C_0}   ${C_Y}warnings: $WARN${C_0}   ${C_R}failed: $FAIL${C_0}"
echo "============================================================"
if [ "$FAIL" -gt 0 ]; then echo " Something required is missing. Fix the [FAIL] lines and run again."; exit 1; fi
[ "$WARN" -gt 0 ] && echo " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them."
exit 0
