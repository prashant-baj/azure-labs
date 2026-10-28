#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-quality.sh  -  Session 13, layer 4: is the behaviour proved, and is the quality bar set?
#                       Stories with acceptance criteria, the spec changed first, scenarios tagged
#                       with IDs, the rule built test-first, quality gates in the spec and the pipeline.
#                       (macOS / Linux / WSL)
#
#  Checks structure, records and git history - never whether a scenario is a good one.
#  That is what the example map, /review-scenarios and the debrief are for. It does not
#  run your tests: the pipeline does that, on every push.
#
#  USAGE
#    chmod +x check-quality.sh               # first time only
#    ./check-quality.sh [path-to-case-repo] [slice-folder]
#
#  Exit code is non-zero only if something required is missing.
#  A PowerShell twin (check-quality.ps1) exists for native Windows.
# =============================================================================

set -uo pipefail
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
if [ -n "${2:-}" ]; then SLICE="$REPO/${2#./}"; [ -d "$SLICE" ] || SLICE="$REPO/specs/${2}"
else SLICE="$(find "$REPO/specs" -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null | sort | tail -1)"; fi
SPEC="$SLICE/spec.md"; STORIES="$SLICE/stories.md"; CI="$REPO/.gitlab-ci.yml"

echo "============================================================"
echo " Junior SWAT Labs - Session 13 - layer 4 check"
echo " $REPO"
echo "============================================================"
[ -d "$REPO/.git" ] || { bad "Not a git repository"; exit 1; }
[ -f "$SPEC" ] || { bad "No slice spec found (specs/NNN-name/spec.md)"; exit 1; }
ok "Slice: specs/$(basename "$SLICE")"
if git -C "$REPO" rev-parse -q --verify refs/tags/L3-working >/dev/null; then BASE="L3-working"; ok "Layer 4 measured from tag L3-working"
else BASE=""; warn "No tag L3-working - measuring the whole history instead"; fi
RANGE="${BASE:+$BASE..}HEAD"

IDS="$(grep -oE '\b(FR|NFR|RULE)-[0-9]{3}[a-z]?\b' "$SPEC" | sort -u)"
RULE_ROWS="$(grep -oE '^\|[[:space:]]*RULE-[0-9]{3}[a-z][[:space:]]*\|' "$SPEC" | grep -oE 'RULE-[0-9]{3}[a-z]' | sort -u)"
FRS="$(grep -oE '^\|[[:space:]]*FR-[0-9]{3}[[:space:]]*\|' "$SPEC" | grep -oE 'FR-[0-9]{3}' | sort -u)"

# --- 1. Stories ------------------------------------------------------------------
hdr "1 · Stories and acceptance criteria"
NSTORY=0; NAC=0; STORY_OK=no
if [ -f "$STORIES" ]; then
  NSTORY=$(grep -cE '^#+[[:space:]]*US-[0-9]+' "$STORIES")
  NAC=$(grep -cE '^\|[[:space:]]*AC-[0-9]+' "$STORIES")
  [ "$NSTORY" -ge 1 ] && ok "$NSTORY stor$( [ "$NSTORY" = 1 ] && echo y || echo ies) in stories.md" || bad "stories.md has no story (## US-001 · …)"
  grep -qiE '^\*\*As\*\*|^As (a|an|the) ' "$STORIES" && ok "Stories are written As / I want / so that" || warn "No 'As … I want … so that …' found"
  grep -qiE 'As (a|an|the) user\b|\*\*As\*\* (a|an|the) user\b' "$STORIES" && warn "A story is for 'the user' - name the real role from spec §2"
  NDELIV=$(grep -cE '^Delivers:.*(FR|RULE|NFR)-[0-9]{3}' "$STORIES")
  [ "$NDELIV" -ge "$NSTORY" ] && [ "$NSTORY" -ge 1 ] && ok "Every story names the IDs it delivers" || warn "$((NSTORY-NDELIV)) stor(ies) without a 'Delivers: FR-…' line"
  if [ "$NAC" -ge 1 ]; then
    ok "$NAC acceptance criteria"
    NOPROOF=$(grep -E '^\|[[:space:]]*AC-[0-9]+' "$STORIES" | grep -cvE '(FR|RULE|NFR)-[0-9]{3}')
    [ "$NOPROOF" -eq 0 ] && ok "Every AC names what it proves" || warn "$NOPROOF AC row(s) do not name a requirement or rule row"
    [ "$NSTORY" -ge 1 ] && [ "$NDELIV" -ge 1 ] && STORY_OK=yes
  else bad "No acceptance criteria (| AC-1 | Given | When | Then | Proves |)"; fi
  UNKNOWN=$(grep -oE '\b(FR|NFR|RULE)-[0-9]{3}[a-z]?\b' "$STORIES" | sort -u | while read -r i; do echo "$IDS" | grep -qx "$i" || echo "$i"; done | xargs)
  [ -z "$UNKNOWN" ] && ok "Every ID in stories.md exists in spec.md" || warn "IDs in stories.md that spec.md does not have: $UNKNOWN"
else bad "No specs/$(basename "$SLICE")/stories.md - /spec-stories writes it (template: templates/stories.md)"; fi
[ -f "$SLICE/example-map.md" ] && ok "Example map kept (example-map.md)" || warn "No example-map.md - the conversation behind the stories is not recorded"

# --- 2. Spec first -----------------------------------------------------------------
hdr "2 · The spec changed first"
SPEC_FIRST=no
SPEC_CHANGES=$(git -C "$REPO" log --format=%H "$RANGE" -- "${SPEC#$REPO/}" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SPEC_CHANGES" -ge 1 ]; then
  ok "spec.md changed in layer 4 ($SPEC_CHANGES commit(s))"
  FIRST_SPEC=$(git -C "$REPO" log --reverse --format=%ct "$RANGE" -- "${SPEC#$REPO/}" | head -1)
  FIRST_FEAT=$(git -C "$REPO" log --reverse --format=%ct --diff-filter=A "$RANGE" -- '*.feature' | head -1)
  if [ -z "$FIRST_FEAT" ] || [ "$FIRST_SPEC" -le "$FIRST_FEAT" ]; then ok "…before the first scenario was written"; SPEC_FIRST=yes
  else warn "The first .feature file came before the first spec change - was the spec changed afterwards to match?"; SPEC_FIRST=yes; fi
else warn "spec.md has not changed since L3-working - what did the example map change? (rule rows, answered and new questions)"; fi
NRULES=$(echo "$RULE_ROWS" | grep -c . )
[ "$NRULES" -ge 1 ] && ok "$NRULES rule rows in the spec" || warn "No rule rows (| RULE-001a | … |) in spec.md §5"
NQ=$(grep -cE 'NEEDS CLARIFICATION' "$SPEC")
[ "$NQ" -ge 1 ] && ok "$NQ open question(s) marked - not guessed" || true

# --- 3. Scenarios ------------------------------------------------------------------
hdr "3 · Executable scenarios, tagged with IDs"
FEATURES="$(cd "$REPO" && find . \( -name node_modules -o -name .git -o -name .claude -o -name target -o -path ./templates \) -prune -o -type f -name '*.feature' -print | sed 's#^\./##' | sort)"
NFEAT=$(echo "$FEATURES" | grep -c .)
SCEN_OK=no; COVER_OK=no
if [ "$NFEAT" -ge 1 ]; then
  INSPEC=$(echo "$FEATURES" | grep -c "^specs/")
  [ "$INSPEC" -eq "$NFEAT" ] && ok "$NFEAT feature file(s), all next to the spec" || warn "$((NFEAT-INSPEC)) feature file(s) outside specs/ - keep them with the spec they prove"
  # one line per scenario: file:line<TAB>tags-in-force
  SCEN="$(for f in $FEATURES; do awk -v F="$f" '
      /^[[:space:]]*@/ { pend = pend " " $0; next }
      /^[[:space:]]*Feature:/ { ftags = pend; pend = ""; next }
      /^[[:space:]]*(Scenario|Scenario Outline|Scenario Template|Example):/ { print F ":" NR "\t" ftags " " pend; pend = ""; next }
      /^[[:space:]]*(Rule|Background|Examples|Scenarios):/ { if ($0 ~ /Rule:/) { rtags = pend }; pend = ""; next }
      ' "$REPO/$f"; done)"
  NSC=$(echo "$SCEN" | grep -c .)
  UNTAGGED=$(echo "$SCEN" | grep -vE '@(FR|NFR|RULE)-[0-9]{3}' | grep -c .)
  ok "$NSC scenario(s)"
  if [ "$NSC" -ge 1 ] && [ "$UNTAGGED" -eq 0 ]; then ok "Every scenario tagged with the ID it proves"; SCEN_OK=yes
  elif [ "$NSC" -ge 1 ]; then bad "$UNTAGGED scenario(s) with no @FR-/@RULE-/@NFR- tag:"; echo "$SCEN" | grep -vE '@(FR|NFR|RULE)-[0-9]{3}' | cut -f1 | head -5 | sed 's/^/         /'; fi
  ALLTXT="$(for f in $FEATURES; do cat "$REPO/$f"; done)"
  TAGGED=$(echo "$ALLTXT" | grep -oE '@(FR|NFR|RULE)-[0-9]{3}[a-z]?' | tr -d '@' | sort -u)
  BADTAG=$(for i in $TAGGED; do echo "$IDS" | grep -qx "$i" || echo "$i"; done | xargs)
  [ -z "$BADTAG" ] && ok "Every tag is an ID in spec.md" || warn "Tags with no such ID in spec.md: $BADTAG"
  MISSING_R=""; for r in $RULE_ROWS; do
    echo "$ALLTXT" | grep -qE "(^|[^A-Za-z0-9-])$r([^a-z0-9]|$)|@${r%?}([^a-z0-9]|$)" || MISSING_R="$MISSING_R $r"
  done
  if [ "$NRULES" -ge 1 ] && [ -z "$MISSING_R" ]; then ok "Every rule row has a scenario"; COVER_OK=yes
  elif [ "$NRULES" -ge 1 ]; then warn "Rule rows with no scenario:$MISSING_R"; fi
  MISSING_F=""; for f in $FRS; do echo "$TAGGED" | grep -qx "$f" || MISSING_F="$MISSING_F $f"; done
  [ -z "$MISSING_F" ] && ok "Every FR has a scenario" || warn "FRs with no scenario yet:$MISSING_F - fine for now; list them in trace.md as 'none yet'"
  if [ "$NRULES" -eq 0 ] && [ "$SCEN_OK" = yes ]; then COVER_OK=yes; fi
  IMP=$(echo "$ALLTXT" | grep -iE '^[[:space:]]*(Given|When|Then|And|But)\b.*\b(click|clicks|button|page|field|types? |enters? |url|http|json|sql|select \* )' | head -3)
  [ -z "$IMP" ] && ok "Scenarios read as behaviour - no clicks, fields, URLs or SQL" || { warn "Imperative steps - say what happens, not how:"; echo "$IMP" | sed 's/^[[:space:]]*/         /'; }
  grep -qE 'Scenario (Outline|Template):' <<< "$ALLTXT" && ok "Rule examples as a Scenario Outline" || warn "No Scenario Outline - a rule with example rows is one outline, rows word for word from the spec"
else bad "No .feature files - /spec-scenarios writes them into specs/$(basename "$SLICE")/features/"; fi

# --- 4. Test first -----------------------------------------------------------------
hdr "4 · Steps, and the rule built test-first"
STEPS=$(cd "$REPO" && grep -rlE 'pytest_bdd|@cucumber/cucumber|io\.cucumber\.java|Reqnroll|godog' --include='*.py' --include='*.js' --include='*.mjs' --include='*.ts' --include='*.java' --include='*.cs' --include='*.go' . 2>/dev/null | grep -vE 'node_modules|/\.claude/' | head -20)
NSTEPS=$(echo "$STEPS" | grep -c .)
STEPS_OK=no
[ "$NSTEPS" -ge 1 ] && { ok "$NSTEPS step-definition file(s)"; STEPS_OK=yes; } || bad "No step definitions found (pytest-bdd, cucumber-js or Cucumber-JVM) - stacks/<stack>/README.md"
NIDTEST=$(cd "$REPO" && grep -rhoiE '(def test_|test\(|it\(|void )[^(]*(rule|fr|nfr)[_-]?[0-9]{3}' --include='*.py' --include='*.js' --include='*.mjs' --include='*.ts' --include='*.java' --exclude-dir=node_modules --exclude-dir=.claude --exclude-dir=templates . 2>/dev/null | wc -l | tr -d ' ')
[ "$NIDTEST" -ge 1 ] && ok "$NIDTEST unit test(s) named after an ID" || warn "No unit test named after a rule or requirement ID (test_rule_002b_…)"
NTEST=$(git -C "$REPO" log --format=%s "$RANGE" 2>/dev/null | grep -ciE '^test(\(.*\))?:')
NFEATC=$(git -C "$REPO" log --format=%s "$RANGE" 2>/dev/null | grep -ciE '^feat(\(.*\))?:')
NREF=$(git -C "$REPO" log --format=%s "$RANGE" 2>/dev/null | grep -ciE '^refactor(\(.*\))?:')
TDD_OK=no
REDFIRST=$(git -C "$REPO" log --reverse --format=%s "$RANGE" 2>/dev/null | awk '{ s = tolower($0) } s ~ /^test(\(.*\))?:/ { t = 1 } s ~ /^feat(\(.*\))?:/ && t { print "yes"; exit }')
if [ "$REDFIRST" = yes ]; then ok "Test-first trail in git: $NTEST test:, $NFEATC feat:, $NREF refactor: commit(s) - a test before the code"; TDD_OK=yes
elif [ "$NTEST" -ge 1 ]; then warn "test: commits, but no feat: commit after one - commit each step: test: (red), feat: (green), refactor:"
else warn "No test: / feat: commits since L3-working - commit each TDD step so the history shows it"; fi
TDDLOG="$SLICE/tdd-log.md"
if [ -f "$TDDLOG" ] && grep -qiE 'red' "$TDDLOG"; then ok "tdd-log.md records the cycles"; TDD_OK=yes; else warn "No tdd-log.md in the slice - /tdd-cycle appends to it"; fi

# --- 5. Pipeline -------------------------------------------------------------------
hdr "5 · The scenarios run in the pipeline"
PIPE_OK=no
if [ -f "$CI" ] && grep -qE 'ci/scenarios\.yml|^scenarios:' "$CI"; then ok "Scenarios job in .gitlab-ci.yml"; PIPE_OK=yes
else warn "No scenarios job - setup-quality adds ci/scenarios.yml and includes it"; fi
if [ -f "$REPO/ci/scenarios.yml" ]; then grep -q 'junit' "$REPO/ci/scenarios.yml" && ok "Scenario results reported to the merge request (junit)" || warn "ci/scenarios.yml has no junit report"; fi
TAGGED_L4=no; git -C "$REPO" rev-parse -q --verify refs/tags/L4-behaviour >/dev/null && TAGGED_L4=yes
PUSHED=no
if git -C "$REPO" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  [ "$(git -C "$REPO" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 1)" -eq 0 ] && PUSHED=yes
fi
[ "$PUSHED" = yes ] && ok "Everything on this branch is pushed" || warn "Not pushed"

# --- 6. Quality gates ----------------------------------------------------------------
hdr "6 · Quality gates - in the spec, and in the pipeline"
QG="$REPO/specs/design/quality-gates.md"; QY="$REPO/ci/quality.yml"
QG_OK=no; QP_OK=no
if [ -f "$QG" ]; then
  NQG=$(grep -cE '^\|[[:space:]]*QG-[0-9]{3}' "$QG")
  [ "$NQG" -ge 5 ] && ok "specs/design/quality-gates.md - $NQG gates" || warn "quality-gates.md has $NQG gate(s) - lint, complexity, secrets, SAST, dependencies at least"
  NORULE=$(grep -E '^\|[[:space:]]*QG-[0-9]{3}' "$QG" | awk -F'|' '{print $4}' | grep -cvE '(E|W|C|NFR|FR|RULE)-[0-9]{3}|ADR|constraints|\b(FR|RULE)\b' || true)
  [ "$NORULE" -eq 0 ] && ok "Every gate names the rule it enforces" || warn "$NORULE gate(s) do not name a rule - a gate with no rule is a habit, not a decision"
  CXB=$(grep -E '^\|[[:space:]]*QG-002' "$QG" | awk -F'|' '{print $(NF-1)}' | grep -oE '[0-9]+' | head -1)
  if [ -n "$CXB" ]; then ok "Complexity baseline recorded ($CXB)"; QG_OK=yes; else warn "No baseline in the QG-002 row - run quality-local, then /quality-gates"; fi
else bad "No specs/design/quality-gates.md - run quality-local, then /quality-gates (template: templates/quality-gates.md)"; fi
if [ -f "$QY" ]; then
  if [ -f "$CI" ] && grep -q 'ci/quality.yml' "$CI"; then ok "ci/quality.yml included in .gitlab-ci.yml" ; INC=yes; else bad "ci/quality.yml is not included in .gitlab-ci.yml"; INC=no; fi
  MISSING=""; for j in qa:lint qa:complexity qa:secrets qa:sast qa:dependencies; do grep -qE "^$j:" "$QY" || MISSING="$MISSING $j"; done
  [ -z "$MISSING" ] && ok "Gates in the pipeline: lint, complexity, secrets, SAST, dependencies" || warn "Missing from ci/quality.yml:$MISSING"
  [ "$INC" = yes ] && [ -z "$MISSING" ] && QP_OK=yes
  OFF=$(for j in qa:secrets qa:sast qa:dependencies qa:lint; do awk -v j="$j:" '$0==j{f=1;next} f && /^[^[:space:]]/{f=0} f && /allow_failure:[[:space:]]*true/{print j}' "$QY"; done | xargs)
  [ -z "$OFF" ] && ok "No blocking gate switched off (allow_failure)" || warn "Blocking gates set to allow_failure: $OFF - is that in quality-gates.md, with a reason?"
  QCB=$(sed -nE 's/^[[:space:]]+QA_COMPLEXITY_BASELINE:[[:space:]]*"([^"]*)".*/\1/p' "$QY" | head -1)
  QCL=$(sed -nE 's/^[[:space:]]+QA_COMPLEXITY_LIMIT:[[:space:]]*"([^"]*)".*/\1/p' "$QY" | head -1)
  [ -n "$QCB" ] && ok "Complexity ratchet on - baseline $QCB" || warn "QA_COMPLEXITY_BASELINE is empty - complexity only reports. Set it from quality-gates.md"
  if [ -f "$QG" ] && [ -n "$QCL" ]; then
    grep -E '^\|[[:space:]]*QG-002' "$QG" | grep -qE "(^|[^0-9])$QCL([^0-9]|$)" && ok "Spec and pipeline agree on the complexity limit ($QCL)" \
      || warn "QA_COMPLEXITY_LIMIT is $QCL, but the QG-002 row says otherwise - the spec decides; fix the pipeline"
  fi
else bad "No ci/quality.yml - setup-quality adds the baseline quality pipeline"; fi
if [ -f "$CI" ]; then
  for j in lint secrets; do grep -qE "^$j:" "$CI" && warn "Session 10 job '$j:' still in .gitlab-ci.yml - qa:$j replaces it; two jobs for one gate drift apart"; done
  LATEST=$(cat "$CI" "$REPO"/ci/*.yml 2>/dev/null | grep -E 'image:|name:' | grep -E ':latest|image:[[:space:]]*[a-z0-9./-]+[[:space:]]*$' | grep -vE 'image:[[:space:]]*$' | head -3)
  [ -z "$LATEST" ] && ok "Every pipeline image pinned to a version" || { warn "Images without a pinned version - a scanner on 'latest' runs whatever was published last:"; echo "$LATEST" | sed 's/^[[:space:]]*/         /'; }
fi

hdr "Ready for layer 5? (see BUILD-ROADMAP.md)"
MISS=0
bar() { if [ "$1" = "yes" ]; then echo "  ${C_G}[ HAVE ]${C_0} $2"; else echo "  ${C_R}[ NEED ]${C_0} $2"; MISS=$((MISS+1)); fi; }
bar $STORY_OK "Stories with acceptance criteria, each naming the IDs it proves"
bar $SPEC_FIRST "The spec changed first - rule rows and questions from the example map"
bar $SCEN_OK "Executable scenarios, every one tagged with its IDs"
bar $COVER_OK "Every rule row has a scenario"
bar $STEPS_OK "Thin step definitions that call the application"
bar $TDD_OK "The rule built test-first - test: before feat:, or a tdd-log"
bar $PIPE_OK "Scenarios run in the pipeline, with a report"
bar $QG_OK "Quality gates in the spec - each naming its rule, with today's baseline"
bar $QP_OK "The baseline quality pipeline - lint, complexity, secrets, SAST, dependencies"
bar $TAGGED_L4 "Tagged L4-behaviour"
echo
[ "$MISS" -eq 0 ] && echo "  ${C_G}READY${C_0} - layer 4 is in. Layer 5 automates the confidence." || echo "  ${C_Y}NOT YET${C_0} - $MISS item(s) above."

echo
echo "============================================================"
echo " ${C_G}ok: $PASS${C_0}   ${C_Y}warnings: $WARN${C_0}   ${C_R}failed: $FAIL${C_0}"
echo "============================================================"
if [ "$FAIL" -gt 0 ]; then echo " Something required is missing. Fix the [FAIL] lines and run again."; exit 1; fi
[ "$WARN" -gt 0 ] && echo " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them."
exit 0
