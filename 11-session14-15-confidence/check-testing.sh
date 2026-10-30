#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-testing.sh  -  Sessions 14 and 15, layer 5: is the confidence automated - and measurable?
#                       A test strategy with thresholds, a suite that grew, API checks, a deploy that
#                       verifies itself, and a scorecard the pipeline decides on. (macOS / Linux / WSL)
#
#  Checks files, records and git history. It does not run your tests or deploy - the pipeline does that,
#  and confidence.md in each pipeline is the evidence.
#
#  USAGE
#    chmod +x check-testing.sh               # first time only
#    ./check-testing.sh [path-to-case-repo]
#
#  Exit code is non-zero only if something required is missing.
#  A PowerShell twin (check-testing.ps1) exists for native Windows.
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
CI="$REPO/.gitlab-ci.yml"; CY="$REPO/ci/confidence.yml"; ST="$REPO/specs/design/test-strategy.md"
natext() { [ -f "$ST" ] && awk 'f { print; if (/^## /) exit; next } /[Nn]ot automated yet/ { f = 1; print }' "$ST"; }   # first block only, like the PS twin
var() { [ -f "$CY" ] && sed -nE "s/^[[:space:]]+$1:[[:space:]]*\"([^\"]*)\".*/\1/p" "$CY" | head -1; }

echo "============================================================"
echo " Junior SWAT Labs - Sessions 14-15 - layer 5 check"
echo " $REPO"
echo "============================================================"
[ -d "$REPO/.git" ] || { bad "Not a git repository"; exit 1; }
if git -C "$REPO" rev-parse -q --verify refs/tags/L4-behaviour >/dev/null; then BASE=L4-behaviour; ok "Layer 5 measured from tag L4-behaviour"
else BASE=""; warn "No tag L4-behaviour - the suite's growth cannot be measured"; fi

# --- 1. Strategy -----------------------------------------------------------------------
hdr "1 - The test strategy - and the thresholds the pipeline decides on"
STRAT_OK=no; NFR_OK=no
if [ -f "$ST" ]; then
  ok "specs/design/test-strategy.md"
  RISKS=$(sed -n '/What could go wrong/,/^## 2/p' "$ST" | grep -E '^\|[[:space:]]*[A-Za-z]' | grep -cvE '^\|[[:space:]]*Risk[[:space:]]*\|')
  [ "$RISKS" -ge 3 ] && ok "$RISKS risks, each with the layer that catches it" || warn "$RISKS risk(s) - what would hurt the client most? (/test-strategy, section 1)"
  grep -qiE 'not automated yet' "$ST" && [ -n "$(natext | sed 1d | grep -E '[A-Za-z]{4}' | grep -v '^## ')" ] \
    && ok "Says what is not automated yet, and why" || warn "No 'Not automated yet, and why' - an honest gap beats a pretty pyramid"
  ROWS=$(grep -E '^\|[[:space:]]*CS-[0-9]{3}[[:space:]]*\|.*\|[[:space:]]*(merge|deploy)[[:space:]]*\|[[:space:]]*$' "$ST")
  NROWS=$(echo "$ROWS" | grep -c .)
  UNSET=$(echo "$ROWS" | awk -F'|' '{print $5}' | grep -cvE '^[[:space:]]*(>=|<=|=|<|>)[[:space:]]*[0-9.]+' || true)
  BADM=$(echo "$ROWS" | awk -F'|' '{gsub(/ /,"",$4); print $4}' | grep -cvxE 'tests\.pass_rate|tests\.count|coverage\.line|api\.pass_rate|e2e\.pass_rate|perf\.p95_ms|perf\.error_rate|smoke\.version|planned\.[a-z0-9_]+' || true)
  if [ "$NROWS" -ge 5 ] && [ "$UNSET" -eq 0 ] && [ "$BADM" -eq 0 ]; then ok "$NROWS confidence thresholds, every one set"; STRAT_OK=yes
  elif [ "$NROWS" -eq 0 ]; then bad "No confidence thresholds (| CS-001 | ... | merge |) - the pipeline has nothing to decide on"
  else warn "$NROWS threshold row(s): $UNSET not set yet, $BADM with an unknown measure - /test-strategy, section 5"; fi
  echo "$ROWS" | grep -qE 'coverage\.line' && ok "Coverage is a signal" || warn "No coverage.line row - coverage is not measured"
  PERF=$(echo "$ROWS" | grep -E 'perf\.(p95_ms|error_rate)')
  if [ -z "$PERF" ]; then warn "No performance threshold - which NFR says how fast is fast enough?"
  elif [ "$(echo "$PERF" | grep -cE 'NFR-[0-9]{3}')" -eq "$(echo "$PERF" | grep -c .)" ]; then ok "Every performance threshold quotes an NFR"; NFR_OK=yes
  else warn "A performance threshold without an NFR - a number nobody decided"; fi
  for m in api.pass_rate smoke.version; do echo "$ROWS" | grep -q "$m" || warn "No $m row"; done
  grep -qE '^## 6\.' "$ST" && ok "Section 6 draws the pipeline from the strategy" || warn "No section 6 - draw the pipeline from the rows: each row, its job, real or planned (template, section 6)"
else bad "No specs/design/test-strategy.md - /test-strategy writes it (template: templates/test-strategy.md)"; fi

# --- 2. The suite ----------------------------------------------------------------------------
hdr "2 - The suite grew - and reports what it proves"
GREW=no; COV=no
count_tests() { git -C "$REPO" grep -hcE '^\s*(async\s+)?def test_|^\s*(test|it)\(|@Test\b' "$1" -- ':!*.claude/*' ':!*node_modules/*' 2>/dev/null | awk '{s+=$1} END {print s+0}'; }
NOW=$(count_tests HEAD)
if [ -n "$BASE" ]; then
  THEN=$(count_tests "$BASE")
  if [ "$NOW" -gt "$THEN" ]; then ok "Tests: $THEN at L4-behaviour, $NOW now"; GREW=yes
  else warn "Tests: $THEN at L4-behaviour, $NOW now - the suite has not grown"; fi
else ok "$NOW tests"; fi
IDN=$(git -C "$REPO" grep -hiE '(def test_|test\(|it\(|void )[^(]*(fr|nfr|rule|def|c)[_-]?[0-9]{3}' -- ':!*.claude/*' ':!*.json' ':!*node_modules/*' 2>/dev/null | wc -l | tr -d ' ')
[ "$IDN" -ge 1 ] && ok "$IDN tests named after an ID" || warn "No tests named after an ID (test_fr_004_...)"
testci() { for f in "$CI" "$REPO"/ci/*.yml; do case "$f" in */ci/confidence.yml|*/ci/quality.yml) ;; *) [ -f "$f" ] && cat "$f" ;; esac; done; }
if testci | grep -qE 'coverage_report|^[[:space:]]+coverage:'; then ok "Coverage reported in the pipeline"; COV=yes
else warn "No coverage in your test job - stacks.md, section 2"; fi
testci | grep -qE 'cov-report=xml|cobertura|jacoco' && ok "Coverage written as a file the scorecard can read" || warn "No coverage XML (cobertura or jacoco) in your pipeline - CS-003 will say NOT MEASURED"
AIN=$(grep -ciE '\|[[:space:]]*\**(kept|changed|rejected|not needed)\**([[:space:]]*\||[[:space:]]+\()' "$REPO/reviews/ai-tests.md" 2>/dev/null)
AI_OK=no
[ "${AIN:-0}" -ge 1 ] && { ok "AI-suggested tests reviewed: $AIN decision(s) in reviews/ai-tests.md"; AI_OK=yes; } || warn "reviews/ai-tests.md has no decisions - /suggest-tests, then log kept / changed / rejected"

# --- 3. API checks -------------------------------------------------------------------------------
hdr "3 - API checks - the same collection before merge and after deploy"
API_OK=no
COL=$(ls "$REPO"/tests/api/*.postman_collection.json 2>/dev/null | head -1)
if [ -n "$COL" ]; then
  NT=$(grep -oE 'pm\.test\(\\?"[^"\\]*' "$COL" | wc -l | tr -d ' ')
  NID=$(grep -oE 'pm\.test\(\\?"(SMOKE|FR-[0-9]{3}|NFR-[0-9]{3}|C-[0-9]{3}|RULE-[0-9]{3}|DEF-[0-9]{3})' "$COL" | wc -l | tr -d ' ')
  STARTER=no; grep -qE '<path>|FR-0nn' "$COL" && STARTER=yes
  [ "$STARTER" = yes ] && warn "${COL#$REPO/} is still the starter - /api-tests writes yours" || ok "${COL#$REPO/}: $NT test(s)"
  [ "$NT" -gt 0 ] && [ "$NID" -eq "$NT" ] && ok "Every API test named after the ID it proves" || warn "$((NT-NID)) API test(s) without an ID at the start of the name"
  SECRET_RE='"(password|token|secret|apikey|api_key)"[[:space:]]*:[[:space:]]*"[^"{]{6,}|"key"[[:space:]]*:[[:space:]]*"[^"]*(password|token|secret|apikey|api_key)[^"]*"[[:space:]]*,[[:space:]]*"value"[[:space:]]*:[[:space:]]*"[^"{]{6,}|Bearer [A-Za-z0-9._-]{20,}'
  cat "$REPO"/tests/api/*.json 2>/dev/null | tr '\r\n' '  ' | grep -qiE "$SECRET_RE" && bad "A secret value in tests/api/ - pass it with --env-var from a pipeline variable" || ok "No secrets in the collection"
  grep -q '{{baseUrl}}' "$COL" && ok "Requests use {{baseUrl}} - one collection, every environment" || warn "Hard-coded URLs - use {{baseUrl}}"
  [ "$NT" -ge 3 ] && [ "$NID" -eq "$NT" ] && [ "$STARTER" = no ] && API_OK=yes
else bad "No tests/api/*.postman_collection.json - /api-tests writes it"; fi
[ -n "$(var APP_START)" ] && ok "api:local on - APP_START: $(var APP_START)" || warn "APP_START is empty - api:local does not run before merge (stacks.md, section 3)"

# --- 4. Deploy and verify (Session 15) -----------------------------------------------------------
hdr "4 - Deploy with measurable confidence (Session 15)"
DEP_OK=no; PERF_OK=no
if [ -f "$CY" ]; then
  [ "$(var CONFIDENCE_DEPLOY)" = on ] && { ok "CONFIDENCE_DEPLOY is on - main builds, deploys and verifies"; DEP_OK=yes; } || warn "CONFIDENCE_DEPLOY is off - Session 15 turns it on"
  APPD="$(var APP_DIR)"; APPD="${APPD:-.}"
  [ -f "$REPO/$APPD/Dockerfile" ] && ok "$APPD/Dockerfile" || warn "No $APPD/Dockerfile - build:image needs it"
  INF="$(var CONFIDENCE_INFRA)"; INF="${INF:-infra}"
  if [ -d "$REPO/$INF" ]; then
    MISS=""; for v in prefix image target_port; do grep -qE "variable[[:space:]]+\"$v\"" "$REPO/$INF"/*.tf 2>/dev/null || MISS="$MISS var.$v"; done
    for o in acr_name acr_login_server app_url; do grep -qE "output[[:space:]]+\"$o\"" "$REPO/$INF"/*.tf 2>/dev/null || MISS="$MISS output.$o"; done
    [ -z "$MISS" ] && ok "$INF/ takes the image and port, and gives back the registry and the URL" || warn "$INF/ is missing:$MISS - the Session 12 starter has them"
  else warn "No $INF/ - deploy:test applies it"; fi
fi
if [ -f "$REPO/tests/perf/smoke.js" ]; then
  TH=no; grep -qE 'thresholds' "$REPO/tests/perf/smoke.js" && TH=yes
  [ "$TH" = yes ] && ok "tests/perf/smoke.js has thresholds" || warn "tests/perf/smoke.js has no thresholds - then it measures, but never decides"
  if grep -qE "PERF_PATHS \|\| '/health'" "$REPO/tests/perf/smoke.js"; then warn "The perf smoke only calls /health - point it at the answer your NFR is about"
  elif [ "$TH" = yes ]; then PERF_OK=yes; fi
else warn "No tests/perf/smoke.js"; fi
if [ -f "$REPO/tests/e2e/package.json" ]; then
  NE=$(grep -rhoE "test\(['\"]" "$REPO/tests/e2e/tests" 2>/dev/null | wc -l | tr -d ' ')
  ok "tests/e2e/: $NE journey(s)"; [ "$NE" -gt 5 ] && warn "More than five end-to-end journeys - keep these few; push the rest down"
else
  grep -qiE '\b(end.to.end|e2e|UI)\b' <(natext 2>/dev/null) && ok "No tests/e2e/ - and the strategy says why" || warn "No tests/e2e/ - if you have a web UI, copy .claude/test-starters/e2e; if not, say so in the strategy"
fi
ls "$REPO"/specs/design/defects/DEF-*.md >/dev/null 2>&1 && ok "Defect analyses: $(ls "$REPO"/specs/design/defects/DEF-*.md | wc -l | tr -d ' ')" || true

# --- 5. The pipeline -------------------------------------------------------------------------------
hdr "5 - The pipeline"
PIPE_OK=no
[ -f "$REPO/ci/confidence.py" ] && ok "ci/confidence.py - the scorecard" || bad "No ci/confidence.py - setup-testing adds it"
if [ -f "$CI" ] && grep -q 'ci/confidence.yml' "$CI"; then ok "ci/confidence.yml included"; PIPE_OK=yes; else bad "ci/confidence.yml not included in .gitlab-ci.yml"; fi
if [ -f "$CI" ]; then
  if grep -qE '^stages:' "$CI"; then
    SL="$(awk '/^stages:/{f=1} f{print} f && !/^stages:/ && /^[^[:space:]#-]/{exit}' "$CI" | sed 's/[][,-]/ /g' | tr -s ' \t\r\n' ' ')"
    for s in check test deploy verify; do echo " $SL " | grep -q " $s " || { bad "stage '$s' missing from stages:"; PIPE_OK=no; }; done
    [ "$PIPE_OK" = yes ] && ok "stages: check, test, deploy, verify"
  else bad "No stages: list in .gitlab-ci.yml - check, test, deploy and verify must be in it"; PIPE_OK=no; fi
fi
[ -f "$REPO/ci/quality.yml" ] && ok "Session 13 quality gates still in the pipeline" || warn "No ci/quality.yml - the gates from Session 13"
MAP_OK=no
if [ -f "$CY" ] && [ -f "$ST" ]; then
  MEAS=" $(echo "$ROWS" | awk -F'|' '{gsub(/ /,"",$4); print $4}' | tr '\n' ' ') "
  PLANNED=$(grep -oE '^"[a-z0-9:_-]+ \(planned\)":' "$CY" | sed -E 's/^"(.*) \(planned\)":$/\1/')
  NPL=$(echo "$PLANNED" | grep -c . || true)
  MM=0
  pm() { case "$1" in verify:smoke) echo "smoke.version";; verify:api) echo "api.pass_rate";; verify:e2e) echo "e2e.pass_rate";; verify:perf) echo "perf.p95_ms perf.error_rate";; *) echo "";; esac; }
  if [ "$(var CONFIDENCE_DEPLOY)" != on ]; then
    for j in verify:smoke verify:api verify:e2e verify:perf; do
      ROWHAS=no; for m in $(pm $j); do case "$MEAS" in *" $m "*) ROWHAS=yes;; esac; done
      JOBHAS=no; echo "$PLANNED" | grep -qx "$j" && JOBHAS=yes
      if [ "$ROWHAS" = yes ] && [ "$JOBHAS" = no ]; then warn "A row needs $j, but its (planned) job is gone - it will not show in today's pipeline"; MM=$((MM+1)); fi
      if [ "$ROWHAS" = no ] && [ "$JOBHAS" = yes ]; then warn "\"$j (planned)\" has no row in the strategy - add the row, or delete the job and say why under 'Not automated yet'"; MM=$((MM+1)); fi
    done
  fi
  for m in $MEAS; do case "$m" in planned.*) grep -q "$m" "$CY" "$CI" "$REPO"/ci/*.yml 2>/dev/null || { warn "Row $m has no (planned) job - copy one in ci/confidence.yml and set PLANNED_MEASURE: \"$m\""; MM=$((MM+1)); };; esac; done
  if [ "$MM" -eq 0 ]; then ok "Every row has a job, every job a row - $NPL planned job(s) mark what is not built yet"; MAP_OK=yes; fi
fi
TAGGED=no; git -C "$REPO" rev-parse -q --verify refs/tags/L5-tested >/dev/null && TAGGED=yes

hdr "Ready for layer 6? (see BUILD-ROADMAP.md)"
MISS=0
bar() { if [ "$1" = "yes" ]; then echo "  ${C_G}[ HAVE ]${C_0} $2"; else echo "  ${C_R}[ NEED ]${C_0} $2"; MISS=$((MISS+1)); fi; }
bar $STRAT_OK "A test strategy with every confidence threshold set"
bar $NFR_OK "Performance thresholds that quote an NFR"
R=no; [ "$GREW" = yes ] && [ "$COV" = yes ] && R=yes; bar $R "A suite that grew, with coverage reported"
bar $API_OK "API checks written from the spec, named after their IDs"
bar $AI_OK "AI-suggested tests reviewed and logged"
bar $PIPE_OK "The confidence pipeline included, stages in place"
bar $MAP_OK "The pipeline drawn from the strategy - every row a job, real or planned"
R=no; [ "$DEP_OK" = yes ] && [ "$PERF_OK" = yes ] && R=yes; bar $R "Deploy on: build once, deploy, verify, decide (Session 15)"
bar $TAGGED "Tagged L5-tested"
echo
[ "$MISS" -eq 0 ] && echo "  ${C_G}READY${C_0} - layer 5 is in. Every merge deploys, with a scorecard you can show." || echo "  ${C_Y}NOT YET${C_0} - $MISS item(s) above."

echo
echo "============================================================"
echo " ${C_G}ok: $PASS${C_0}   ${C_Y}warnings: $WARN${C_0}   ${C_R}failed: $FAIL${C_0}"
echo "============================================================"
if [ "$FAIL" -gt 0 ]; then echo " Something required is missing. Fix the [FAIL] lines and run again."; exit 1; fi
[ "$WARN" -gt 0 ] && echo " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them."
exit 0
