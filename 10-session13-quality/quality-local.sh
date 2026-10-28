#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  quality-local.sh  -  Session 13: the pipeline's quality gates, on your laptop, before you push
#                       (macOS / Linux / WSL)
#
#  Runs the same checks as ci/quality.yml - lint, complexity, secrets, SAST, dependencies, IaC -
#  with whichever tools you have installed, and tells you how to get the ones you do not.
#  Writes .quality/local-report.md in your repo (git-ignored): /quality-gates reads it to record
#  today's baseline in specs/design/quality-gates.md.
#
#  USAGE
#    ./quality-local.sh <path-to-case-repo> [app-folder]
#
#  Exit code 1 if a gate that blocks in the pipeline has findings - so you can run it before every push.
#  A PowerShell twin (quality-local.ps1) exists for native Windows.
# =============================================================================

set -uo pipefail
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_G=$'\033[0;32m'; C_R=$'\033[0;31m'; C_Y=$'\033[0;33m'; C_B=$'\033[0;36m'; C_0=$'\033[0m'
else C_G=""; C_R=""; C_Y=""; C_B=""; C_0=""; fi
hdr()  { echo; echo "${C_B}==> $1${C_0}"; }

REPO="${1:-.}"; APP="${2:-}"
[ -d "$REPO" ] || { echo "Path not found: $REPO"; exit 1; }
REPO="$(cd "$REPO" && pwd)"; cd "$REPO" || exit 1
QA="$REPO/ci/quality.yml"
var() { [ -f "$QA" ] && sed -nE "s/^[[:space:]]+$1:[[:space:]]*\"([^\"]*)\".*/\1/p" "$QA" | head -1; }
[ -n "$APP" ] || APP="$(var QA_APP_DIR)"; APP="${APP:-.}"
LIMIT="$(var QA_COMPLEXITY_LIMIT)"; LIMIT="${LIMIT:-10}"
BASE_CX="$(var QA_COMPLEXITY_BASELINE)"; BASE_IAC="$(var QA_IAC_BASELINE)"
STACK=""
[ -f "$APP/pom.xml" ] && STACK=java; [ -z "$STACK" ] && [ -f "$APP/package.json" ] && STACK=node
[ -z "$STACK" ] && { [ -f "$APP/pyproject.toml" ] || [ -f "$APP/requirements.txt" ]; } && STACK=python

echo "============================================================"
echo " Junior SWAT Labs - Session 13 - quality gates, locally"
echo " $REPO  (app: $APP, stack: ${STACK:-unknown})"
echo "============================================================"
mkdir -p .quality; RPT=.quality/local-report.md
ROWS=(); BLOCK=0
row() {  # gate | tool | result | blocks in CI | note
  ROWS+=("| $1 | $2 | $3 | $4 | $5 |")
  case "$3" in
    clean*)   echo "  ${C_G}[ OK ]${C_0} $1 - $3" ;;
    skipped*) echo "  ${C_Y}[SKIP]${C_0} $1 - $5" ;;
    *)        if [ "$4" = yes ]; then echo "  ${C_R}[FIND]${C_0} $1 - $3"; BLOCK=1; else echo "  ${C_Y}[FIND]${C_0} $1 - $3 ($4)"; fi ;;
  esac
}
have() { command -v "$1" >/dev/null 2>&1; }
num() { tr -cd '0-9\n' | head -1; }

hdr "1 · Lint and format (E-010, E-003, E-006)"
case "$STACK" in
  python)
    if have ruff; then
      F=$(ruff format --check "$APP" 2>&1 | sed -nE 's/^([0-9]+) files? would be reformatted.*/\1/p' | head -1); F=${F:-0}
      L=$(ruff check "$APP" --output-format=concise 2>/dev/null | grep -cE '^[^ ].*:[0-9]+:[0-9]+:' || true)
      [ $((F+L)) -eq 0 ] && row "Lint" "ruff" "clean" yes "" || row "Lint" "ruff" "$L finding(s), $F file(s) to reformat" yes "ruff check $APP · ruff format $APP"
    else row "Lint" "ruff" "skipped" yes "pip install ruff"; fi ;;
  node)
    if [ -x "$APP/node_modules/.bin/eslint" ]; then
      L=$( (cd "$APP" && npx --no-install eslint . -f unix 2>/dev/null) | grep -cE ':[0-9]+:[0-9]+:' || true)
      P=$( (cd "$APP" && npx --no-install prettier --check . 2>&1) | grep -c '^\[warn\] [^C]' || true)
      [ $((L+P)) -eq 0 ] && row "Lint" "eslint, prettier" "clean" yes "" || row "Lint" "eslint, prettier" "$L finding(s), $P file(s) to format" yes "npx eslint . · npx prettier --write ."
    else row "Lint" "eslint, prettier" "skipped" yes "npm ci in $APP, with ESLint and Prettier configured"; fi ;;
  java)
    if have mvn && grep -qE 'spotless|checkstyle' "$APP/pom.xml"; then
      if (cd "$APP" && mvn -B -q spotless:check checkstyle:check >/dev/null 2>&1); then row "Lint" "spotless, checkstyle" "clean" yes ""
      else row "Lint" "spotless, checkstyle" "findings" yes "mvn spotless:apply · mvn checkstyle:check"; fi
    else row "Lint" "spotless, checkstyle" "skipped" yes "Maven with Spotless and Checkstyle in pom.xml (Session 10)"; fi ;;
  *) row "Lint" "-" "skipped" yes "no build file found in $APP" ;;
esac

hdr "2 · Complexity (E-003)"
if have lizard; then
  set -f
  N=$(lizard -C "$LIMIT" -w -x '*/node_modules/*' -x '*/tests/*' -x '*/test/*' -x '*/.claude/*' -x '*/target/*' -x '*/specs/*' "$APP" 2>/dev/null | grep -c 'warning:' || true)
  set +f
  if [ "$N" -eq 0 ]; then row "Complexity" "lizard" "clean" ratchet "limit $LIMIT"
  elif [ -n "$BASE_CX" ] && [ "$N" -le "$BASE_CX" ]; then row "Complexity" "lizard" "$N above $LIMIT - within baseline $BASE_CX" ratchet ""
  elif [ -n "$BASE_CX" ]; then row "Complexity" "lizard" "$N above $LIMIT - baseline is $BASE_CX" yes "lizard -C $LIMIT -w $APP"
  else row "Complexity" "lizard" "$N function(s) above $LIMIT" "no baseline yet" "lizard -C $LIMIT -w $APP"; fi
else row "Complexity" "lizard" "skipped" ratchet "pip install lizard"; fi

hdr "3 · Secrets (E-008)"
if have gitleaks; then
  OUT=$(gitleaks git --redact --no-banner . 2>&1); N=$(echo "$OUT" | sed -nE 's/.*leaks found: ([0-9]+).*/\1/p' | head -1); N=${N:-0}
  [ "$N" -eq 0 ] && row "Secrets" "gitleaks" "clean" yes "" || row "Secrets" "gitleaks" "$N secret(s) in git history" yes "rotate first, then remove - gitleaks git -v ."
else row "Secrets" "gitleaks" "skipped" yes "github.com/gitleaks/gitleaks/releases - or brew install gitleaks"; fi

hdr "4 · Static analysis - SAST"
if have semgrep; then
  semgrep scan --config p/default --metrics off --exclude specs --exclude .claude --quiet --json -o .quality/semgrep.json . >/dev/null 2>&1
  E=$(grep -o '"severity": *"ERROR"' .quality/semgrep.json 2>/dev/null | wc -l | tr -d ' ')
  W=$(grep -o '"severity": *"WARNING"' .quality/semgrep.json 2>/dev/null | wc -l | tr -d ' ')
  if [ "$E" -eq 0 ] && [ "$W" -eq 0 ]; then row "SAST" "semgrep" "clean" yes "severity ERROR blocks"
  elif [ "$E" -eq 0 ]; then row "SAST" "semgrep" "$W warning(s)" "reported" "semgrep scan --config p/default ."
  else row "SAST" "semgrep" "$E error(s), $W warning(s)" yes "semgrep scan --config p/default ."; fi
else row "SAST" "semgrep" "skipped" yes "pip install semgrep (Windows: use WSL or Docker)"; fi

hdr "5 · Dependencies"
if have osv-scanner; then
  rc=0; osv-scanner scan source -r --format json "$APP" > .quality/osv.json 2>/dev/null || rc=$?
  N=$(grep -o '"id": *"\(GHSA\|PYSEC\|CVE\|RUSTSEC\|GO\)-[^"]*"' .quality/osv.json 2>/dev/null | sort -u | wc -l | tr -d ' ')
  if [ "$rc" = 128 ]; then row "Dependencies" "osv-scanner" "no lockfile or pinned requirements" yes "pin your dependencies"
  elif [ "$rc" = 0 ]; then row "Dependencies" "osv-scanner" "clean" yes ""
  else row "Dependencies" "osv-scanner" "$N known vulnerabilit(ies)" yes "osv-scanner scan source -r $APP"; fi
else row "Dependencies" "osv-scanner" "skipped" yes "github.com/google/osv-scanner/releases - or brew install osv-scanner"; fi

hdr "6 · Infrastructure as code"
if [ -d infra ] && ls infra/*.tf >/dev/null 2>&1; then
  if have checkov; then
    N=$(checkov -d infra --framework terraform --compact --quiet 2>/dev/null | sed -nE 's/.*Failed checks: ([0-9]+).*/\1/p' | head -1); N=${N:-0}
    if [ "$N" -eq 0 ]; then row "IaC" "checkov" "clean" ratchet ""
    elif [ -n "$BASE_IAC" ] && [ "$N" -le "$BASE_IAC" ]; then row "IaC" "checkov" "$N failed - within baseline $BASE_IAC" ratchet ""
    elif [ -n "$BASE_IAC" ]; then row "IaC" "checkov" "$N failed - baseline is $BASE_IAC" yes "checkov -d infra --compact"
    else row "IaC" "checkov" "$N failed check(s)" "no baseline yet" "checkov -d infra --compact"; fi
  else row "IaC" "checkov" "skipped" ratchet "pip install checkov"; fi
else row "IaC" "checkov" "clean - no infra/*.tf yet" ratchet ""; fi

{
  echo "# Local quality report"
  echo
  echo "*$(date '+%Y-%m-%d %H:%M') · branch $(git rev-parse --abbrev-ref HEAD 2>/dev/null) · commit $(git rev-parse --short HEAD 2>/dev/null) · app $APP · complexity limit $LIMIT*"
  echo
  echo "| Gate | Tool | Result | Blocks in CI | How to look |"
  echo "|---|---|---|---|---|"
  printf '%s\n' "${ROWS[@]}"
  echo
  echo "Not committed. \`/quality-gates\` reads it to record the baseline in \`specs/design/quality-gates.md\`."
} > "$RPT"

echo
echo "============================================================"
echo " Report: $RPT"
if [ "$BLOCK" -eq 1 ]; then
  echo " ${C_R}A gate that blocks in the pipeline has findings.${C_0} Fix, or triage with /triage-findings, before you push."
  echo "============================================================"; exit 1
fi
echo " ${C_G}Nothing that blocks.${C_0} Skipped tools still run in the pipeline."
echo "============================================================"
exit 0
