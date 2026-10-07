#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-spec.sh  -  Session 9: is this spec one a team could build from?
#                    (macOS / Linux / WSL)
#
#  Checks structure, IDs, sources and traceability - never the quality of your
#  thinking. That is what the debrief is for.
#
#  USAGE
#    chmod +x check-spec.sh                 # first time only
#    ./check-spec.sh [path-to-case-repo] [slice-folder]
#      slice-folder defaults to the highest-numbered specs/NNN-* folder
#
#  Exit code is non-zero if any REQUIRED check fails.
#  A PowerShell twin (check-spec.ps1) exists for native Windows.
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

SPEC="$SLICE/spec.md"; PLAN="$SLICE/plan.md"; TASKS="$SLICE/tasks.md"; CONST="$REPO/constitution.md"

echo "============================================================"
echo " Junior SWAT Labs - Session 9 - spec check"
echo " $REPO"
echo "============================================================"

# Helpers ---------------------------------------------------------------------
# table rows whose first cell is an ID with the given prefix, e.g. FR
rows()    { grep -E "^\|[[:space:]]*$2-[0-9]{3}[a-z]?[[:space:]]*\|" "$1" 2>/dev/null | grep -vE '<[a-zA-Z][^>]*>'; }
# real task lines - template placeholders excluded
tasks()   { grep -E '^- \[[ xX]\] T[0-9]{3}' "$1" 2>/dev/null | grep -vE '<[a-zA-Z.][^>]*>'; }
ids()     { grep -oE "\b$2-[0-9]{3}\b" "$1" 2>/dev/null | sort -u; }
# cell N (1-based, after the leading pipe) of each row, trimmed
cell()    { awk -F'|' -v n="$1" '{ c=$(n+1); gsub(/^[ \t]+|[ \t]+$/,"",c); print c }'; }
section() { awk -v h="$2" 'index($0,h)==1{f=1;next} /^## /{f=0} f' "$1" 2>/dev/null; }

# --- Structure ----------------------------------------------------------------
hdr "The four layers"
[ -d "$REPO/.git" ] && ok "It is a git repository" || bad "Not a git repository"
[ -d "$REPO/docs" ] && ok "docs/ - the evidence" || warn "docs/ missing - layer 1, the evidence"
[ -f "$CONST" ] && ok "constitution.md" || bad "constitution.md missing - run organise-specs first"
[ -f "$REPO/specs/README.md" ] && ok "specs/README.md" || warn "specs/README.md missing"
if [ -d "$REPO/specs/design" ]; then
  MISSING=""
  for f in solution-definition.md integration-decisions.md nfr-register.md constraints.md contracts adr; do
    [ -e "$REPO/specs/design/$f" ] || MISSING="$MISSING $f"
  done
  if [ -z "$MISSING" ]; then ok "specs/design/ holds the whole Module 2 record"
  else warn "specs/design/ is missing:$MISSING"; fi
else bad "specs/design/ missing - run organise-specs first"; fi
NCMD=$(ls "$REPO/.claude/commands"/spec-*.md 2>/dev/null | wc -l | tr -d ' ')
[ "$NCMD" -ge 6 ] && ok "$NCMD /spec- commands in .claude/commands/" || warn "Only $NCMD /spec- commands found in .claude/commands/"

if [ -z "$SLICE" ] || [ ! -d "$SLICE" ]; then bad "No slice folder (specs/NNN-name/) found"; echo; echo "Stopping."; exit 1; fi
ok "Slice: specs/$(basename "$SLICE")"
[ -f "$SPEC" ] || { bad "spec.md missing in the slice folder"; echo; echo "Stopping."; exit 1; }

# --- Constitution ---------------------------------------------------------------
hdr "Constitution"
if [ -f "$CONST" ]; then
  if grep -qE '<case name>|<date>|<names>' "$CONST"; then bad "Template placeholders still in constitution.md"
  else ok "Placeholders replaced"; fi
  NC=$(rows "$CONST" C | wc -l | tr -d ' '); NQ=$(rows "$CONST" Q | wc -l | tr -d ' ')
  NCF=$(rows "$CONST" C | cell 2 | grep -c . || true); NQF=$(rows "$CONST" Q | cell 2 | grep -c . || true)
  if [ "$NCF" -ge 1 ]; then ok "$NCF rule(s) you were handed"; else warn "No rules in section 2 - every enterprise hands you some"; fi
  if [ "$NQF" -ge 1 ]; then ok "$NQF quality floor(s)"; else warn "No quality floors in section 3"; fi
  NOSRC=$( { rows "$CONST" C | awk -F'|' '{c=$3; s=$4; gsub(/[ \t]/,"",c); gsub(/[ \t]/,"",s); if (c!="" && s=="") print}'; \
             rows "$CONST" Q | awk -F'|' '{c=$3; s=$5; gsub(/[ \t]/,"",c); gsub(/[ \t]/,"",s); if (c!="" && s=="") print}'; } | wc -l | tr -d ' ')
  [ "$NOSRC" -eq 0 ] && ok "Every filled rule has a source" || warn "$NOSRC rule(s) with no source - a rule with no source is an opinion"
  W=$(ids "$CONST" W | wc -l | tr -d ' ')
  [ "$W" -ge 6 ] && ok "House rules W-001 to W-006 kept" || warn "Only $W house rule(s) - W-001 to W-006 were meant to stay"
fi

# --- Spec -------------------------------------------------------------------
hdr "Spec - what and why"
S0=$(section "$SPEC" "## 0." | grep -vE '^[[:space:]]*$|^<!--|^[[:space:]]*(Written|One paragraph|coding hours|-->)' )
if [ -z "$S0" ] || echo "$S0" | grep -q '<One paragraph.>'; then bad "Section 0 is empty - the group writes it by hand, first"
else ok "Section 0 written"; fi

NFR_=$(rows "$SPEC" FR | cell 1 | grep -c . || true)
NIN=$(rows "$SPEC" IN | cell 2 | grep -c . || true)
NRULE=$(rows "$SPEC" RULE | cell 2 | grep -c . || true)
NNFR=$(rows "$SPEC" NFR | cell 2 | grep -c . || true)

if [ "$NFR_" -eq 0 ]; then bad "No functional requirements (FR-001 ...)"
elif [ "$NFR_" -gt 15 ]; then warn "$NFR_ functional requirements - is this a slice, or a platform?"
else ok "$NFR_ functional requirement(s)"; fi

NOSHALL=$(rows "$SPEC" FR | cell 2 | grep -vc 'shall' || true)
if [ "$NFR_" -gt 0 ]; then [ "$NOSHALL" -eq 0 ] && ok "Every FR uses 'shall'" || warn "$NOSHALL FR row(s) without 'shall' - EARS form, please"; fi
if rows "$SPEC" FR | cell 2 | grep -qE '^If .*then the system shall'; then ok "At least one 'If ... then' requirement - the case nobody writes"
else warn "No 'If <unwanted case>, then the system shall ...' requirement - what happens when it goes wrong?"; fi

if [ "$NIN" -ge 2 ]; then ok "$NIN inputs described"
elif [ "$NIN" -eq 1 ]; then warn "Only one input - does everything really come from one place?"
else warn "Section 3 (what comes in) is empty"; fi
[ "$NRULE" -ge 1 ] && ok "$NRULE worked example(s) of the rule" || warn "No worked examples for the rule in section 5 - given this, expect that"
[ "$NNFR" -ge 1 ] && ok "$NNFR quality requirement(s) for this slice" || warn "No quality requirements in section 8"

# Sources: FR col 3, IN col 6, RULE col 4, NFR col 5 - only rows that have content
nosrc() { rows "$SPEC" "$1" | awk -F'|' -v n="$2" '{ c=$3; s=$(n+1); gsub(/^[ \t]+|[ \t]+$/,"",c); gsub(/^[ \t]+|[ \t]+$/,"",s); if (c!="" && s=="") print }' | wc -l | tr -d ' '; }
NOSRC=$(( $(nosrc FR 3) + $(nosrc IN 6) + $(nosrc RULE 4) + $(nosrc NFR 5) ))
[ "$NOSRC" -eq 0 ] && ok "Every row has a source" || warn "$NOSRC row(s) with no source - where did it come from?"

TECH=$(grep -v '^<!--' "$SPEC" | grep -oE '\b(Java|Spring|Python|FastAPI|Django|Flask|Node\.?js|Express|NestJS|React|Angular|\.NET|C#|Kafka|RabbitMQ|Redis|Postgres|PostgreSQL|MySQL|MongoDB|Cosmos|SQL Server|Azure|AWS|GCP|Docker|Kubernetes|AKS|REST|GraphQL|JSON|XML|gRPC|Service Bus|Event Grid|Lambda|microservice)s?\b' | sort -u | tr '\n' ' ')
[ -z "$TECH" ] && ok "No technology names in the spec" || warn "Technology in the spec: $TECH- that belongs in plan.md"

VAGUE=$(grep -v '^<!--' "$SPEC" | grep -oiE '\b(fast|quickly|timely|user.friendly|seamless|real.time|as required|appropriate|robust)\b' | sort -u | tr '\n' ' ')
[ -z "$VAGUE" ] && ok "No words that cannot fail" || warn "Words that cannot fail: $VAGUE- run /spec-clarify"

NNC=$(grep 'NEEDS CLARIFICATION' "$SPEC" | grep -v '<question>' | grep -o 'NEEDS CLARIFICATION' | wc -l | tr -d ' ')
if [ "$NNC" -eq 0 ]; then ok "No open [NEEDS CLARIFICATION] markers"
else
  WHO=$(section "$SPEC" "## 10." | grep -E '^\|[[:space:]]*[0-9]+' | cell 3 | grep -c . || true)
  warn "$NNC [NEEDS CLARIFICATION] marker(s) open - fine, if each is in section 10 with who can answer ($WHO named)"
fi

# --- Plan -------------------------------------------------------------------
hdr "Plan - how"
if [ ! -f "$PLAN" ] || grep -q '<How the slice works' "$PLAN"; then warn "plan.md not written yet - /spec-plan"
else
  ok "plan.md written"
  CC=$(section "$PLAN" "## 2. Constitution check" | grep -E '^\|' | grep -vE '^\|[[:space:]]*(Rule|-+)[[:space:]]*\|' | cell 1 | grep -c . || true)
  [ "$CC" -ge 1 ] && ok "Constitution check has $CC row(s)" || warn "Constitution check is empty"
  MISSING=""
  for id in $(ids "$SPEC" FR); do grep -q "$id" "$PLAN" || MISSING="$MISSING $id"; done
  [ -z "$MISSING" ] && ok "Every FR has a home in the plan" || warn "FR with no home in the plan:$MISSING"
  BADLINK=""
  for c in $(grep -oE 'contracts/[A-Za-z0-9._-]+\.md' "$PLAN" | sort -u); do
    [ -f "$REPO/specs/design/$c" ] || BADLINK="$BADLINK $c"
  done
  [ -z "$BADLINK" ] && ok "Every contract the plan links exists" || warn "Plan links contracts that do not exist:$BADLINK"
  STACK=$(section "$PLAN" "## 8." | grep -oE '\b(Java|Spring|Python|FastAPI|Django|Flask|Node\.?js|Express|NestJS|\.NET|C#)\b' | sort -u | tr '\n' ' ')
  [ -z "$STACK" ] && ok "Stack left open, as it should be for now" || warn "Section 8 names a stack ($STACK) - it has not been decided yet"
  NMER=$(grep -c '^```mermaid' "$PLAN" || true)
  if grep -q '<this slice>' "$PLAN"; then warn "Diagrams in section 11 still hold template placeholders"
  elif [ "$NMER" -ge 2 ]; then ok "$NMER diagrams as code in the plan"
  elif [ "$NMER" -eq 1 ]; then warn "Only one diagram - an area map and a sequence with its failure path are both expected"
  else warn "No diagrams as code (mermaid) in plan.md section 11"; fi
  if grep -q '^```mermaid' "$PLAN" && ! grep -qE '^[[:space:]]*(alt|opt)\b' "$PLAN"; then
    warn "The sequence diagram shows no failure branch (alt / opt)"
  fi
  INF=$(grep -c '(inferred)' "$PLAN" || true)
  [ "$INF" -gt 0 ] && ok "$INF line(s) marked (inferred) - read them aloud before you accept them" || true
fi

# --- Tasks ------------------------------------------------------------------
hdr "Tasks - in what order"
NT=$(tasks "$TASKS" | grep -c . || true)
if [ ! -f "$TASKS" ] || [ "${NT:-0}" -eq 0 ]; then warn "tasks.md has no tasks yet - /spec-tasks"
else
  if [ "$NT" -gt 25 ]; then warn "$NT tasks - more than twenty-five usually means the slice is too big"
  else ok "$NT task(s)"; fi
  NOID=$(tasks "$TASKS" | grep -vcE '\b(FR|IN|RULE|NFR|C|Q|W)-[0-9]{3}' || true)
  [ "$NOID" -eq 0 ] && ok "Every task names a requirement ID" || warn "$NOID task(s) name no requirement - why do they exist?"
  NTEST=$(tasks "$TASKS" | grep -ciE '\btests?\b' || true)
  [ "$NTEST" -ge 1 ] && ok "$NTEST test task(s)" || warn "No test tasks - W-003 says tests come first"
  MISSING=""
  for id in $(ids "$SPEC" FR) $(ids "$SPEC" RULE); do grep -q "$id" "$TASKS" || MISSING="$MISSING $id"; done
  [ -z "$MISSING" ] && ok "Every FR and RULE has a task" || warn "No task for:$MISSING - it will not get built"
  GHOST=""
  for id in $(grep -E '^- \[' "$TASKS" | grep -oE '\b(FR|RULE|IN|NFR)-[0-9]{3}\b' | sort -u); do grep -q "$id" "$SPEC" || GHOST="$GHOST $id"; done
  [ -z "$GHOST" ] && ok "Every ID in tasks exists in the spec" || warn "Tasks name IDs the spec does not have:$GHOST"
fi
[ -f "$SLICE/trace.md" ] && ok "trace.md present" || warn "No trace.md - run /spec-trace and read the gaps together"

# --- Git ------------------------------------------------------------------------
hdr "Commit discipline and the remote"
if [ -d "$REPO/.git" ]; then
  REL="${SPEC#$REPO/}"
  SC=$(git -C "$REPO" rev-list --count HEAD -- "$REL" 2>/dev/null || echo 0)
  if [ "$SC" -ge 2 ]; then ok "$SC commits touch spec.md (section 0 by hand first, then the rest)"
  else warn "Only $SC commit(s) touch spec.md - was section 0 committed before the assistant saw it?"; fi
  for f in plan tasks; do
    C=$(git -C "$REPO" rev-list --count HEAD -- "${SLICE#$REPO/}/$f.md" 2>/dev/null || echo 0)
    [ "$C" -ge 2 ] && ok "$f.md committed after it was filled" || warn "$f.md has not been committed since the template"
  done
  URL=$(git -C "$REPO" remote get-url origin 2>/dev/null || true)
  if [ -z "$URL" ]; then warn "No remote - run connect-gitlab before you leave"
  else
    case "$URL" in *gitlab.stackroute.in*) ok "Remote is your GitLab project" ;; *) warn "Remote is not on gitlab.stackroute.in: $URL" ;; esac
    if git -C "$REPO" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
      AHEAD=$(git -C "$REPO" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
      [ "$AHEAD" -eq 0 ] && ok "Everything is pushed" || warn "$AHEAD commit(s) not pushed yet"
    else warn "Branch has no upstream - push with connect-gitlab"; fi
  fi
fi

echo
echo "============================================================"
echo " ${C_G}ok: $PASS${C_0}   ${C_Y}warnings: $WARN${C_0}   ${C_R}failed: $FAIL${C_0}"
echo "============================================================"
if [ "$FAIL" -gt 0 ]; then echo " Something required is missing. Fix the [FAIL] lines and run again."; exit 1; fi
[ "$WARN" -gt 0 ] && echo " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them."
exit 0
