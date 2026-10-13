#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-ai-engineering.sh  -  Sessions 11 and 12, layer 3: does the slice work,
#                              built through merge requests, validated, with the
#                              AI feature spec'd and guarded?  (macOS / Linux / WSL)
#
#  Checks structure, records and git discipline - never whether the code is good.
#  That is what the review threads, the validation and the debrief are for.
#
#  USAGE
#    chmod +x check-ai-engineering.sh        # first time only
#    ./check-ai-engineering.sh [path-to-case-repo] [slice-folder]
#
#  Exit code is non-zero only if something required is missing - or a secret is committed.
#  A PowerShell twin (check-ai-engineering.ps1) exists for native Windows.
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
SPEC="$SLICE/spec.md"; TASKS="$SLICE/tasks.md"; CI="$REPO/.gitlab-ci.yml"

echo "============================================================"
echo " Junior SWAT Labs - Sessions 11-12 - layer 3 check"
echo " $REPO"
echo "============================================================"

cell() { awk -F'|' -v n="$1" '{ c=$(n+1); gsub(/^[ \t]+|[ \t]+$/,"",c); print c }'; }
[ -d "$REPO/.git" ] || { bad "Not a git repository"; exit 1; }
[ -f "$SPEC" ] || { bad "No slice spec found (specs/NNN-name/spec.md)"; exit 1; }
ok "Slice: specs/$(basename "$SLICE")"
if git -C "$REPO" rev-parse -q --verify refs/tags/L2-design >/dev/null; then BASE="L2-design"; ok "Layer 3 measured from tag L2-design"
else BASE=""; warn "No tag L2-design - measuring the whole history instead"; fi
RANGE="${BASE:+$BASE..}HEAD"

# --- 1. The pipeline -------------------------------------------------------------
hdr "1 · The pipeline"
if [ ! -f "$CI" ]; then bad "No .gitlab-ci.yml - run setup-ai-engineering"
else
  ok ".gitlab-ci.yml present"
  grep -qE 'ci/ai-review\.yml|^ai-review:' "$CI" && ok "AI review runs on every merge request" || warn "AI review not included - add:  include: [{ local: ci/ai-review.yml }]"
  grep -qE 'reports:|junit' "$CI" && ok "Test results reported to the merge request (junit)" || warn "No test job with a junit report yet - 08-session10-excellence/ci/ has starters"
  grep -q '^spec-present:' "$CI" && warn "The placeholder job spec-present is still there - replace it with your real test job"
fi
[ -f "$REPO/ci/post-review.mjs" ] && ok "ci/post-review.mjs present" || warn "ci/post-review.mjs missing - the review cannot post its threads"
LEAK=$(git -C "$REPO" grep -nIE 'sk-ant-[A-Za-z0-9_-]{20,}|glpat-[A-Za-z0-9_-]{20,}|CLAUDE_CODE_OAUTH_TOKEN[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9_-]{20,}|ANTHROPIC_API_KEY[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9_-]{20,}' 2>/dev/null | head -3)
[ -z "$LEAK" ] && ok "No tokens or keys committed" \
  || { bad "A token or key is committed - revoke it now, then remove it (W-004):"; echo "$LEAK" | cut -d: -f1,2 | sed 's/^/           /; s/$/  (value hidden)/'; }

# --- 2. Building through merge requests ------------------------------------------
hdr "2 · The slice, built through merge requests"
NMERGE=$(git -C "$REPO" log --merges --oneline $RANGE 2>/dev/null | grep -c . || true)
[ "$NMERGE" -ge 3 ] && ok "$NMERGE merge(s) in layer 3 - work arrived task by task" \
  || warn "$NMERGE merge(s) in layer 3 - one merge request per task, or a few tasks each"
CC=$(git -C "$REPO" log --no-merges --format='%s' $RANGE -- '*.py' '*.java' '*.kt' '*.js' '*.ts' '*.cs' '*.go' \
  ':!specs/**' ':!docs/**' ':!templates/**' ':!examples/**' ':!.claude/**' ':!ci/**' 2>/dev/null)
NCC=$(echo "$CC" | grep -c . || true); NOT=$(echo "$CC" | grep -vcE 'T[0-9]{3}|refactor:|fix:|finding' || true)
if [ "$NCC" -eq 0 ]; then warn "No code commits in layer 3 yet"
elif [ "$NOT" -eq 0 ]; then ok "All $NCC code commit(s) name a task, a fix or a finding"
else warn "$NOT of $NCC code commit(s) name no task - 'T009: … (FR-001)'"; fi
if [ -f "$TASKS" ]; then
  TOT=$(grep -cE '^- \[[ xX]\] T[0-9]{3}' "$TASKS" || true); DONE=$(grep -cE '^- \[[xX]\] T[0-9]{3}' "$TASKS" || true)
  [ "$TOT" -gt 0 ] && ok "tasks.md: $DONE of $TOT task(s) ticked" || warn "No tasks in tasks.md"
  [ "$TOT" -gt 0 ] && [ "$DONE" -eq 0 ] && warn "No task ticked yet - tick a task in the same merge request that finishes it"
fi
N=$(git -C "$REPO" log --oneline $RANGE -- README.md 2>/dev/null | grep -c . || true)
[ "$N" -gt 0 ] && ok "README.md changed in layer 3 - docs move with the code" || warn "README.md not changed in layer 3 - does it still say how to run the slice?"
N=$(git -C "$REPO" log --oneline $RANGE -- "${SLICE#$REPO/}/trace.md" 2>/dev/null | grep -c . || true)
[ "$N" -gt 0 ] && ok "trace.md changed in layer 3" || warn "trace.md not changed in layer 3 - re-run /spec-trace: which requirements now have code and tests?"

# --- 3. The AI-assisted feature ----------------------------------------------------
hdr "3 · The AI-assisted feature (Session 12)"
EVAL=$(find "$REPO" -type f -iname '*eval*set*.json' -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/examples/*' 2>/dev/null | head -1)
if [ -z "$EVAL" ]; then warn "No eval set yet (eval-set.json) - /spec-ai-feature writes it"
else
  NEV=$(grep -oE '"EVAL-[0-9]{3}"' "$EVAL" | sort -u | wc -l | tr -d ' ')
  NGR=$(grep -cE '"guardrail"[[:space:]]*:[[:space:]]*true' "$EVAL" || true)
  NSRC=$(grep -oE '"source"[[:space:]]*:' "$EVAL" | wc -l | tr -d ' ')
  [ "$NEV" -ge 6 ] && ok "Eval set: $NEV examples (${EVAL#$REPO/})" || warn "Eval set has $NEV example(s) - at least six, from the evidence"
  [ "$NGR" -ge 1 ] && ok "$NGR guardrail example(s) - input that tries to instruct the model" || warn "No guardrail example - add one that tries to give the model instructions"
  [ "$NSRC" -ge "$NEV" ] && ok "Every eval example cites a source" || warn "Some eval examples have no source - where did they come from?"
fi
NIF=$(grep -cE '^\|[[:space:]]*FR-[0-9]{3}[[:space:]]*\|[[:space:]]*If ' "$SPEC" || true)
[ "$NIF" -ge 2 ] && ok "$NIF 'If ... then' requirements in the spec" || warn "$NIF 'If' requirement(s) - the AI feature needs its own: AI down, answer not allowed, instructions in input"
FAKE=$(git -C "$REPO" grep -lIiE 'class Fake|fake[A-Z_]|new Fake|Fake[A-Z][a-z]+\(' -- ':!examples/**' ':!.claude/**' 2>/dev/null | head -1)
[ -n "$FAKE" ] && ok "Guardrails tested with a fake (${FAKE})" || warn "No fake found in the tests - test the guardrails without a model, key or network"
[ -f "$REPO/.env.example" ] && ok ".env.example lists the configuration names" || warn "No .env.example - list the names (model, key) with empty values"

# --- 4. Validation ------------------------------------------------------------------
hdr "4 · Validation — four lenses, decided by people"
VAL=$(ls "$SLICE"/reviews/*L3*.md "$SLICE"/reviews/*validation*.md 2>/dev/null | sort -u | tail -1)
UNDEC=1
if [ -z "$VAL" ]; then warn "No validation in specs/$(basename "$SLICE")/reviews/ - run /validate-ai-code (Session 12)"
else
  ROWS=$(grep -E '^\|[[:space:]]*[0-9]+[[:space:]]*\|' "$VAL")
  NF=$(echo "$ROWS" | grep -c . || true)
  ok "Validation: ${VAL#$REPO/} - $NF finding(s)"
  LENSES=$(echo "$ROWS" | cell 2 | tr 'A-Z' 'a-z' | grep -oE 'correctness|security|maintainability|compliance' | sort -u | wc -l | tr -d ' ')
  [ "$LENSES" -ge 3 ] && ok "$LENSES of the four lenses used" || warn "Only $LENSES lens(es) used - look again through the others"
  UNDEC=$(echo "$ROWS" | cell 8 | grep -c '^$' || true)
  [ "$NF" -gt 0 ] && { [ "$UNDEC" -eq 0 ] && ok "Every finding decided by the group" || warn "$UNDEC finding(s) not decided - fix, debt, or overruled with a reason"; }
  [ "$NF" -eq 0 ] && UNDEC=0
  grep -qiE 'Tests[[:space:]]*\|[^|]*\|[[:space:]]*[A-Za-z0-9]' "$VAL" && ok "Real tool results quoted" || warn "The 'What the tools said' table is empty - run the tools, quote them"
fi

# --- 5. Tag and push ------------------------------------------------------------------
hdr "5 · The tag"
TAGGED=no; git -C "$REPO" rev-parse -q --verify refs/tags/L3-working >/dev/null && TAGGED=yes
[ "$TAGGED" = yes ] && ok "Tag L3-working" || warn "No tag L3-working yet - tag main at the end of Session 12"
PUSHED=no
if git -C "$REPO" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  [ "$(git -C "$REPO" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 1)" -eq 0 ] && PUSHED=yes
fi
[ "$PUSHED" = yes ] && ok "Everything on this branch is pushed" || warn "Not pushed"

hdr "Ready for layer 4? (see BUILD-ROADMAP.md)"
MISS=0
bar() { if [ "$1" = "yes" ]; then echo "  ${C_G}[ HAVE ]${C_0} $2"; else echo "  ${C_R}[ NEED ]${C_0} $2"; MISS=$((MISS+1)); fi; }
R=no; [ -f "$CI" ] && grep -qE 'ci/ai-review\.yml|^ai-review:' "$CI" && R=yes; bar $R "AI review in the pipeline"
R=no; [ "$NMERGE" -ge 1 ] && R=yes; bar $R "Work merged through merge requests"
R=no; [ -n "$EVAL" ] && [ "${NEV:-0}" -ge 6 ] && [ "${NGR:-0}" -ge 1 ] && R=yes; bar $R "AI feature spec'd, with an eval set and a guardrail example"
R=no; [ -n "$VAL" ] && [ "$UNDEC" -eq 0 ] && R=yes; bar $R "Validation through the four lenses, every finding decided"
R=no; [ -z "$LEAK" ] && R=yes; bar $R "No tokens or keys in the repository"
bar $TAGGED "Tagged L3-working"
echo
[ "$MISS" -eq 0 ] && echo "  ${C_G}READY${C_0} - layer 3 is in. Layer 4 proves the behaviour." || echo "  ${C_Y}NOT YET${C_0} - $MISS item(s) above."

echo
echo "============================================================"
echo " ${C_G}ok: $PASS${C_0}   ${C_Y}warnings: $WARN${C_0}   ${C_R}failed: $FAIL${C_0}"
echo "============================================================"
if [ "$FAIL" -gt 0 ]; then echo " Something required is missing. Fix the [FAIL] lines and run again."; exit 1; fi
[ "$WARN" -gt 0 ] && echo " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them."
exit 0
