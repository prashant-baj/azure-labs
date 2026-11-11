#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-review.sh  -  Session 18, layer 7: has the build been reviewed - and did the review change anything?
#                      A readiness checklist with evidence, a runbook someone else can use, the board's
#                      findings and the client's feedback decided, and the top findings fixed, test first.
#                      (macOS / Linux / WSL)
#
#  Checks files, records and git history. It does not judge the evidence - the board does that.
#
#  USAGE
#    chmod +x check-review.sh               # first time only
#    ./check-review.sh [path-to-case-repo]
#
#  Exit code is non-zero only if something required is missing.
#  A PowerShell twin (check-review.ps1) exists for native Windows.
# =============================================================================

set -u
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
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
RD="$REPO/specs/design/readiness.md"; RB="$REPO/ops/runbook.md"
FD="$REPO/specs/review/findings.md"; FB="$REPO/specs/review/feedback.md"
lc() { tr '[:upper:]' '[:lower:]'; }
trim() { sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'; }
tests() { git -C "$REPO" grep "$@" -- '*test*' '*Test*' '*spec.*' 'tests/*' ':!*.claude/*' ':!*.md' 2>/dev/null; }

# Rows of the readiness checklist with a given prefix (PR, OR, CR) - "ID|evidence|status|note", one per line
rows() { [ -f "$RD" ] && tr -d '\r' < "$RD" | grep -E "^\|[[:space:]]*$1-[0-9]{2}[[:space:]]*\|" \
  | awk -F'|' '{ for (i=2;i<=7;i++) { gsub(/^[ \t]+|[ \t]+$/, "", $i) } print $2 "|" $5 "|" tolower($6) "|" $7 }'; }
# Readiness lines: total, with a status, met without evidence, partly/gap without a finding or backlog, n.a. without a reason
stats() {   # stats <prefix> -> "total filled noev nolink noreason"
  rows "$1" | awk -F'|' '
    { t++; s=$3
      if (s ~ /^(met|partly|gap|n\.a\.|n\/a|na)$/) f++
      if (s == "met" && $2 == "") ne++
      if ((s == "partly" || s == "gap") && $4 !~ /(REV-[0-9]|FB-[0-9]|[Bb]acklog)/) nl++
      if ((s == "n.a." || s == "n/a" || s == "na") && $4 == "") nr++ }
    END { print t+0, f+0, ne+0, nl+0, nr+0 }'; }
# Evidence in "met" rows that names a path (a backticked token with a slash) that is not in the repo
missing_evidence() {
  rows "$1" | awk -F'|' '$3 == "met" { print $2 }' | grep -oE '`[A-Za-z0-9_./-]+/[A-Za-z0-9_./-]+`' | tr -d '`' \
    | while read -r p; do [ -e "$REPO/$p" ] || echo "$p"; done | sort -u; }

echo "============================================================"
echo " Junior SWAT Labs - Session 18 - layer 7 check"
echo " $REPO"
echo "============================================================"
[ -d "$REPO/.git" ] || { bad "Not a git repository"; exit 1; }
if git -C "$REPO" rev-parse -q --verify refs/tags/L6-production >/dev/null; then BASE=L6-production; ok "Layer 7 measured from tag L6-production"
else BASE=""; warn "No tag L6-production - review what you have; what is missing is a finding"; fi

checklist() {   # checklist <prefix> <label> -> prints lines, sets CL_OK
  read -r T F NE NL NR <<< "$(stats "$1")"
  CL_OK=no
  if [ "$T" -eq 0 ]; then bad "No $2 lines ($1-nn) in specs/design/readiness.md - setup-review adds them"; return; fi
  [ "$F" -eq "$T" ] && ok "$T $2 lines, every one with a status" || warn "$F of $T $2 lines have a status (met, partly, gap, n.a.) - /readiness-check"
  [ "$NE" -eq 0 ] && ok "Every 'met' line names its evidence" || warn "$NE 'met' line(s) with no evidence - no evidence, no met"
  [ "$NL" -eq 0 ] && ok "Every 'partly' or 'gap' line names its finding or backlog item" || warn "$NL 'partly' or 'gap' line(s) without a REV-0nn or backlog item - an unowned gap"
  [ "$NR" -eq 0 ] || warn "$NR 'n.a.' line(s) without a reason"
  MISS="$(missing_evidence "$1" | tr '\n' ' ' | sed 's/ $//')"
  [ -z "$MISS" ] && ok "Every path named as evidence is in the repo" || warn "Evidence that is not in the repo: $MISS"
  [ "$F" -eq "$T" ] && [ "$NE" -eq 0 ] && [ "$NL" -eq 0 ] && [ "$NR" -eq 0 ] && [ -z "$MISS" ] && CL_OK=yes
  read -r MET <<< "$(rows "$1" | awk -F'|' '$3 == "met" { n++ } END { print n+0 }')"
  read -r GAP <<< "$(rows "$1" | awk -F'|' '$3 == "gap" || $3 == "partly" { n++ } END { print n+0 }')"
  echo "         $MET met, $GAP partly or gap"
}

# --- 1. Production readiness ------------------------------------------------------------------
hdr "1 - Production readiness - every line with evidence, or an owned gap"
PR_OK=no
if [ -f "$RD" ]; then ok "specs/design/readiness.md"; checklist PR "production readiness"; PR_OK=$CL_OK
else bad "No specs/design/readiness.md - setup-review starts it, /readiness-check fills it"; fi

# --- 2. Operations readiness -------------------------------------------------------------------
hdr "2 - Operations readiness - can someone else run it?"
OR_OK=no; RB_OK=no
if [ -f "$RD" ]; then
  checklist OR "operations readiness"; OR_OK=$CL_OK
  read -r CT CF CNE CNL CNR <<< "$(stats CR)"
  if [ "$CT" -ge 2 ] && [ "$CF" -eq "$CT" ]; then ok "Your case's $CT lines have a status"
  elif [ "$CT" -ge 2 ]; then warn "$CF of $CT case lines (CR-nn) have a status"; OR_OK=no
  else warn "No case lines (CR-01, CR-02) - copy yours from <lab>/templates/case-lines/"; OR_OK=no; fi
fi
if [ -f "$RB" ]; then
  LEFT=$(tr -d '\r' < "$RB" | grep -o '(fill in)' | wc -l | tr -d ' ')
  if [ "$LEFT" -eq 0 ]; then ok "ops/runbook.md - every section written"; RB_OK=yes
  else warn "ops/runbook.md - $LEFT _(fill in)_ left - /runbook drafts it from the repo"; fi
  grep -qiE 'rollback:test|roll back' "$RB" && ok "The runbook says how to roll back" || warn "The runbook does not say how to roll back"
  grep -qiE 'rotate' "$RB" && ok "The runbook says how to rotate a secret" || warn "The runbook does not say how to rotate a secret"
else warn "No ops/runbook.md - setup-review starts it, /runbook drafts it"; fi

# --- 3. The board's findings ---------------------------------------------------------------------
hdr "3 - The board's findings - recorded and decided"
FD_OK=no; VERDICT=no
FROWS=""
[ -f "$FD" ] && FROWS="$(tr -d '\r' < "$FD" | grep -E '^\|[[:space:]]*REV-[0-9]+[[:space:]]*\|' \
  | awk -F'|' '{ for (i=2;i<=9;i++) { gsub(/^[ \t]+|[ \t]+$/, "", $i) } if ($5 != "") print $2 "|" tolower($3) "|" tolower($7) "|" tolower($8) "|" $9 }')"
NF_=$(echo "$FROWS" | grep -c . || true)
if [ ! -f "$FD" ]; then warn "No specs/review/findings.md - setup-review starts it"
else
  [ "$NF_" -ge 3 ] && ok "$NF_ findings from the board" || warn "$NF_ finding(s) recorded - copy every finding from the board's scorecard (at least three)"
  NSEV=$(echo "$FROWS" | awk -F'|' 'NF > 1 && $2 !~ /^(high|medium|low)$/ { n++ } END { print n+0 }')
  NDEC=$(echo "$FROWS" | awk -F'|' 'NF > 1 && $3 !~ /^(fix now|spec change|backlog|accepted)/ { n++ } END { print n+0 }')
  NHIGH=$(echo "$FROWS" | awk -F'|' 'NF > 1 && $2 == "high" { n++ } END { print n+0 }')
  [ "$NSEV" -eq 0 ] && [ "$NF_" -gt 0 ] && ok "Every finding has a severity ($NHIGH high)" || { [ "$NF_" -gt 0 ] && warn "$NSEV finding(s) without a severity (high, medium, low)"; }
  [ "$NDEC" -eq 0 ] && [ "$NF_" -gt 0 ] && ok "Every finding has a decision" || { [ "$NF_" -gt 0 ] && warn "$NDEC finding(s) without a decision (fix now, spec change, backlog, accepted) - /triage-review"; }
  [ "$NF_" -ge 3 ] && [ "$NSEV" -eq 0 ] && [ "$NDEC" -eq 0 ] && FD_OK=yes
fi
if [ -f "$RD" ] && tr -d '\r' < "$RD" | grep -E '^\*\*Verdict:\*\*' | grep -vq '(fill in)'; then ok "The board's verdict is recorded in the readiness checklist"; VERDICT=yes
else warn "The board's verdict is not in specs/design/readiness.md section 4 yet"; fi

# --- 4. Customer feedback ------------------------------------------------------------------------
hdr "4 - Customer feedback - decided, not promised"
FB_OK=no
BROWS=""
[ -f "$FB" ] && BROWS="$(tr -d '\r' < "$FB" | grep -E '^\|[[:space:]]*FB-[0-9]+[[:space:]]*\|' \
  | awk -F'|' '{ for (i=2;i<=7;i++) { gsub(/^[ \t]+|[ \t]+$/, "", $i) } if ($4 != "") print $2 "|" tolower($5) "|" tolower($6) "|" $3 }')"
NB=$(echo "$BROWS" | grep -c . || true)
if [ ! -f "$FB" ]; then warn "No specs/review/feedback.md - setup-review starts it"
else
  [ "$NB" -ge 1 ] && ok "$NB piece(s) of feedback from the client's people" || warn "No feedback recorded - write down what the client's people said in step 4, in their words"
  NTY=$(echo "$BROWS" | awk -F'|' 'NF > 1 && $2 !~ /^(defect|spec change|new request|question)/ { n++ } END { print n+0 }')
  NBD=$(echo "$BROWS" | awk -F'|' 'NF > 1 && $3 !~ /^(fix now|spec change|backlog|declined)/ { n++ } END { print n+0 }')
  NWHO=$(echo "$BROWS" | awk -F'|' 'NF > 1 && $4 == "" { n++ } END { print n+0 }')
  [ "$NTY" -eq 0 ] && [ "$NB" -gt 0 ] && ok "Every piece has a type" || { [ "$NB" -gt 0 ] && warn "$NTY piece(s) without a type (defect, spec change, new request, question)"; }
  [ "$NBD" -eq 0 ] && [ "$NB" -gt 0 ] && ok "Every piece has a decision" || { [ "$NB" -gt 0 ] && warn "$NBD piece(s) without a decision (fix now, spec change, backlog, declined)"; }
  [ "$NWHO" -eq 0 ] || warn "$NWHO piece(s) without who said it"
  [ "$NB" -ge 1 ] && [ "$NTY" -eq 0 ] && [ "$NBD" -eq 0 ] && FB_OK=yes
fi

# --- 5. Remediation ------------------------------------------------------------------------------
hdr "5 - The review changed something - the top findings fixed, test first"
FIX_OK=no
NDONE=$(echo "$FROWS" | awk -F'|' 'NF > 1 && $4 == "done" { n++ } END { print n+0 }')
NDNL=$(echo "$FROWS" | awk -F'|' 'NF > 1 && $4 == "done" && $5 == "" { n++ } END { print n+0 }')
[ "$NDONE" -ge 1 ] && ok "$NDONE finding(s) done" || warn "No finding is done yet - fix the top one or two today (step 6)"
[ "$NDNL" -eq 0 ] || warn "$NDNL done finding(s) without a link to the test, merge request or spec change"
NTR=$(tests -hiE '(def |test\(|it\(|void |@DisplayName\(.)[^(]*(rev|fb)[_-]?[0-9]{2,3}' | wc -l | tr -d ' ')
[ "$NTR" -ge 1 ] && ok "$NTR test(s) named after a finding or feedback (test_rev_0nn_...)" || warn "No test named after a finding (test_rev_0nn_...) - a fix starts with a test, seen red"
NSP=$(git -C "$REPO" grep -lE '(REV|FB)-[0-9]{2}' -- 'specs/*' ':!specs/review/*' ':!specs/design/readiness.md' 2>/dev/null | wc -l | tr -d ' ')
[ "$NSP" -ge 1 ] && ok "$NSP spec, strategy or ADR file(s) changed for a finding" || warn "No spec, strategy or ADR names a finding - the spec changes first"
if [ -n "$BASE" ]; then NCM=$(git -C "$REPO" log --oneline -E --grep='(REV|FB)-[0-9]{2}' "$BASE..HEAD" 2>/dev/null | wc -l | tr -d ' ')
else NCM=$(git -C "$REPO" log --oneline -E --grep='(REV|FB)-[0-9]{2}' 2>/dev/null | wc -l | tr -d ' '); fi
[ "$NCM" -ge 1 ] && ok "$NCM commit(s) name a finding" || warn "No commit names a finding - fix: REV-0nn <what> - test first"
[ "$NDONE" -ge 1 ] && [ "$NDNL" -eq 0 ] && [ "$NTR" -ge 1 ] && FIX_OK=yes
TAGGED=no; git -C "$REPO" rev-parse -q --verify refs/tags/L7-reviewed >/dev/null && TAGGED=yes

hdr "Ready for the integrated demo? (see BUILD-ROADMAP.md)"
MISS=0
bar() { if [ "$1" = "yes" ]; then echo "  ${C_G}[ HAVE ]${C_0} $2"; else echo "  ${C_R}[ NEED ]${C_0} $2"; MISS=$((MISS+1)); fi; }
bar $PR_OK "Production readiness - every line with evidence, or an owned gap"
bar $OR_OK "Operations readiness - every line, and your case's two"
bar $RB_OK "A runbook someone outside the group can use"
R=no; [ "$FD_OK" = yes ] && [ "$VERDICT" = yes ] && R=yes; bar $R "The board's findings recorded and decided, and its verdict"
bar $FB_OK "The client's feedback triaged - no promises"
bar $FIX_OK "The top findings fixed, each with a test named after it"
bar $TAGGED "Tagged L7-reviewed"
echo
[ "$MISS" -eq 0 ] && echo "  ${C_G}READY${C_0} - layer 7 is in. Reviewed by a board - and here is what you fixed." || echo "  ${C_Y}NOT YET${C_0} - $MISS item(s) above."

echo
echo "============================================================"
echo " ${C_G}ok: $PASS${C_0}   ${C_Y}warnings: $WARN${C_0}   ${C_R}failed: $FAIL${C_0}"
echo "============================================================"
if [ "$FAIL" -gt 0 ]; then echo " Something required is missing. Fix the [FAIL] lines and run again."; exit 1; fi
[ "$WARN" -gt 0 ] && echo " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them."
exit 0
