#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  check-production.sh  -  Sessions 16 and 17, layer 6: is it secure, observable and ready for production?
#                          A threat model with tested controls, secrets from the environment, a scan of
#                          the running service, one business and one technical signal in Application
#                          Insights, alerts, a drill and a rollback. (macOS / Linux / WSL)
#
#  Checks files, records and git history. It does not deploy or query Azure - the pipeline does that,
#  and confidence.md (dast.*, obs.* rows) in each pipeline is the evidence.
#
#  USAGE
#    chmod +x check-production.sh            # first time only
#    ./check-production.sh [path-to-case-repo]
#
#  Sections 1-4 are Session 16, sections 5-8 Session 17.
#  Exit code is non-zero only if something required is missing.
#  A PowerShell twin (check-production.ps1) exists for native Windows.
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
CI="$REPO/.gitlab-ci.yml"; PY="$REPO/ci/production.yml"; ST="$REPO/specs/design/test-strategy.md"
TM="$REPO/specs/design/threat-model.md"; OS="$REPO/specs/design/observability.md"; INF="$REPO/infra"
pvar() { [ -f "$PY" ] && sed -nE "s/^[[:space:]]+$1:[[:space:]]*\"([^\"]*)\".*/\1/p" "$PY" | head -1; }
flat() { [ -f "$1" ] && tr -d '\r' < "$1" | tr '\n' ' '; }
# your code: everything tracked except specs, templates, pipeline, Terraform, docs and Claude's files
code() { git -C "$REPO" grep "$@" -- . ':!*.claude/*' ':!specs/*' ':!templates/*' ':!ci/*' ':!infra/*' ':!*.md' ':!.gitlab-ci.yml' ':!*test*' ':!*Test*' 2>/dev/null; }
tests() { git -C "$REPO" grep "$@" -- '*test*' '*Test*' '*spec.*' 'tests/*' ':!*.claude/*' ':!*.md' 2>/dev/null; }
rows() { [ -f "$ST" ] && tr -d '\r' < "$ST" | grep -E '^\|[[:space:]]*CS-[0-9]{3}[[:space:]]*\|.*\|[[:space:]]*(merge|deploy)[[:space:]]*\|[[:space:]]*$'; }

echo "============================================================"
echo " Junior SWAT Labs - Sessions 16-17 - layer 6 check"
echo " $REPO"
echo "============================================================"
[ -d "$REPO/.git" ] || { bad "Not a git repository"; exit 1; }
if git -C "$REPO" rev-parse -q --verify refs/tags/L5-tested >/dev/null; then ok "Layer 6 measured from tag L5-tested"
else warn "No tag L5-tested - layer 5 first, or tag what you have"; fi

# --- 1. Threat model ------------------------------------------------------------------------
hdr "1 - The threat model - every threat a control and a test"
THREAT_OK=no
if [ -f "$TM" ]; then
  ok "specs/design/threat-model.md"
  TROWS=$(tr -d '\r' < "$TM" | grep -E '^\|[[:space:]]*T-[0-9]{2}[[:space:]]*\|' | awk -F'|' '{ t=$4; gsub(/[[:space:]]/,"",t); if (t != "") print }')
  NT=$(echo "$TROWS" | grep -c . || true)
  STRIDE=0; for w in Spoof Tamper Repudiat Information Denial Elevation; do echo "$TROWS" | awk -F'|' '{print $3}' | grep -qi "$w" && STRIDE=$((STRIDE+1)); done
  NOCTL=$(echo "$TROWS" | awk -F'|' '{ c=$5; gsub(/[[:space:]]/,"",c); if (c == "") n++ } END { print n+0 }')
  UNPROVED=""; for id in $(echo "$TROWS" | grep -oE '^\|[[:space:]]*T-[0-9]{2}' | grep -oE 'T-[0-9]{2}'); do
    n="${id#T-}"; proof="$(echo "$TROWS" | grep -E "^\|[[:space:]]*$id[[:space:]]*\|" | awk -F'|' '{print $6}')"
    echo "$proof" | grep -qE 'verify:|qa:' && continue
    tests -qiE "(^|[^a-z0-9])t[_-]?$n([^0-9]|$)" && continue
    UNPROVED="$UNPROVED $id"
  done
  [ "$NT" -ge 4 ] && ok "$NT threats, across $STRIDE of the six STRIDE letters" || warn "$NT threat(s) written - STRIDE letter by letter, what could an outsider, a user out of role, an insider do? (/threat-model)"
  [ "$NOCTL" -eq 0 ] && [ "$NT" -gt 0 ] && ok "Every threat names its control" || { [ "$NT" -gt 0 ] && warn "$NOCTL threat(s) with no control - SEC-0nn, or move it to 'Accepted for now'"; }
  if [ "$NT" -gt 0 ] && [ -z "$UNPROVED" ]; then ok "Every threat is proved - a test named after it, or a pipeline job"
  elif [ "$NT" -gt 0 ]; then warn "No test named after:$UNPROVED - test_sec_0nn_t0n_..., red first"; fi
  ACC=$(tr -d '\r' < "$TM" | sed -n '/[Aa]ccepted for now/,/^## /p' | grep -E '^\|[[:space:]]*[A-Za-z]' | grep -cvE '^\|[[:space:]]*Threat[[:space:]]*\|' || true)
  [ "$ACC" -ge 1 ] && ok "$ACC risk(s) accepted for now, written down" || warn "Nothing under 'Accepted for now' - is every threat really fixed in this slice?"
  [ "$NT" -ge 4 ] && [ "$NOCTL" -eq 0 ] && [ -z "$UNPROVED" ] && THREAT_OK=yes
else bad "No specs/design/threat-model.md - /threat-model writes it (setup-production starts it)"; fi
TN="$REPO/specs/design/threat-notes.md"
if [ -f "$TN" ]; then
  DONE=$(tr -d '\r' < "$TN" | grep -ciE '^- \[x\]' || true); OPEN=$(tr -d '\r' < "$TN" | grep -cE '^- \[ \]' || true)
  if [ "$OPEN" -eq 0 ] && [ "$DONE" -gt 0 ]; then ok "Case notes: all $DONE checks ticked (specs/design/threat-notes.md)"
  else warn "Case notes: $DONE of $((DONE+OPEN)) checks ticked - specs/design/threat-notes.md, 'Before you finish step 2'"; fi
else warn "No specs/design/threat-notes.md - your case's checks: copy <lab>/case-notes/case-<letter>-*.md there"; fi

# --- 2. Controls ------------------------------------------------------------------------------
hdr "2 - The controls - in the code, tested, named after their threats"
SEC_OK=no
NSEC=$(tests -hiE '(def |test\(|it\(|void |@DisplayName\(.)[^(]*sec[_-]?[0-9]{3}' | wc -l | tr -d ' ')
[ "$NSEC" -ge 3 ] && ok "$NSEC security tests named after their control (test_sec_001_...)" || warn "$NSEC security test(s) named SEC-0nn - one per control, red first (stacks.md, section 1)"
code -qiE 'X-Content-Type-Options|helmet\(' && ok "Security headers set in the code (SEC-002)" || warn "No security headers in the code - stacks.md, section 2"
code -qiE 'compare_digest|timingSafeEqual|MessageDigest\.isEqual' && ok "Secrets compared in constant time" || warn "No constant-time comparison found - hmac.compare_digest / timingSafeEqual / MessageDigest.isEqual"
code -qiE 'x-api-key|api_key|apikey' && ok "Protected routes ask for a key, not only a role header (T-01)" || warn "No API key check found in the code - does a role header alone still get in?"
[ "$NSEC" -ge 3 ] && SEC_OK=yes

# --- 3. Secrets -------------------------------------------------------------------------------
hdr "3 - Secrets - from the environment, never in git"
SECRETS_OK=yes
TRACKED=$(git -C "$REPO" ls-files | grep -E '(\.tfvars|\.tfstate|\.tfstate\.backup|(^|/)\.env|\.pem|\.key|fed-cred\.json)$' || true)
if [ -n "$TRACKED" ]; then bad "In git, and must not be: $(echo $TRACKED) - git rm --cached, rotate the secret, add to .gitignore"; SECRETS_OK=no
else ok "No .tfvars, state, .env, keys or credentials files in git"; fi
if [ -f "$INF/secrets.tf" ]; then
  flat "$INF/secrets.tf" | grep -qE 'sensitive[[:space:]]*=[[:space:]]*true' && ok "infra/secrets.tf - the secret variables are sensitive" || { warn "infra/secrets.tf has no sensitive = true - plan output would show the value"; SECRETS_OK=no; }
  flat "$INF/secrets.tf" | grep -qE 'default[[:space:]]*=[[:space:]]*"[^"]+"' && { bad "infra/secrets.tf has a default value - a secret's value never goes in a file"; SECRETS_OK=no; }
else warn "No infra/secrets.tf - setup-production adds it"; SECRETS_OK=no; fi
if grep -qs 'app_secret_names' "$INF/main.tf"; then ok "main.tf hands each secret to the Container App as a secret, not a plain setting"
else warn "main.tf does not use local.app_secret_names - paste the snippet (WORKSHOP-S16.md, step 4)"; SECRETS_OK=no; fi
NTF=$( { [ -f "$PY" ] && tr -d '\r' < "$PY"; } | grep -cE '^[[:space:]]+TF_VAR_[a-z0-9_]+:[[:space:]]*"\$[A-Z0-9_]+"' || true)
[ "$NTF" -ge 1 ] && ok "$NTF GitLab variable(s) handed to Terraform in ci/production.yml - secrets stay masked" || { warn "No TF_VAR_<name>: \"\$VARIABLE\" line in ci/production.yml - how does the secret reach Terraform?"; SECRETS_OK=no; }
LEAK=0; for e in "$REPO"/tests/api/*environment*.json; do [ -f "$e" ] || continue   # a "key": "...apiKey..." with a non-empty "value"
  flat "$e" | grep -qiE '"key"[[:space:]]*:[[:space:]]*"[^"]*(key|token|secret|password)[^"]*"[[:space:]]*,[[:space:]]*"value"[[:space:]]*:[[:space:]]*"[^"]+"' && LEAK=$((LEAK+1))
done
[ "$LEAK" -eq 0 ] && ok "Postman environments hold no key, token or password values" || { bad "$LEAK Postman environment(s) hold a key or token value - empty it; the pipeline passes it with --env-var"; SECRETS_OK=no; }

# --- 4. DAST -----------------------------------------------------------------------------------
hdr "4 - The scan of the running service"
DAST_OK=no; INC=no
if [ -f "$PY" ]; then
  ok "ci/production.yml"
  grep -qs 'ci/production.yml' "$CI" && { ok "Included from .gitlab-ci.yml"; INC=yes; } || bad "ci/production.yml is not included from .gitlab-ci.yml"
  grep -qE '^verify:dast:' "$PY" && ok "verify:dast scans the deployed service after every deploy" || warn "No verify:dast job"
else bad "No ci/production.yml - setup-production adds it"; fi
R=$(rows)
echo "$R" | grep -qE 'dast\.high' && ok "The strategy has a dast.high row" || warn "No dast.high row in the strategy - the scan decides nothing"
echo "$R" | grep -E 'dast\.high' | awk -F'|' '{print $5}' | grep -qE '^[[:space:]]*=[[:space:]]*0[[:space:]]*$' && ok "dast.high = 0 - no high-risk finding is allowed" || { echo "$R" | grep -qE 'dast\.high' && warn "dast.high is not '= 0' - which high-risk finding would you deploy with?"; }
echo "$R" | grep -qE 'dast\.medium' && ok "dast.medium row - a ratchet from the first scan" || warn "No dast.medium row - set it from the first scan's count, then it only goes down"
[ "$INC" = yes ] && grep -qE '^verify:dast:' "$PY" && echo "$R" | grep -qE 'dast\.high' && DAST_OK=yes

# --- 5. Observability spec ----------------------------------------------------------------------
hdr "5 - The observability spec - one business signal, one technical signal"
OBS_SPEC_OK=no; METRIC="$(pvar OBS_BUSINESS_METRIC)"
if [ -f "$OS" ]; then
  ok "specs/design/observability.md"
  BIZ=$(tr -d '\r' < "$OS" | grep -E '^\|[[:space:]]*OBS-001[[:space:]]*\|' | grep -i 'business' | awk -F'|' '{ s=$4; gsub(/[[:space:]`]/,"",s); if (s != "" && s !~ /^<name>/) print }')
  TEC=$(tr -d '\r' < "$OS" | grep -E '^\|[[:space:]]*OBS-002[[:space:]]*\|' | grep -i 'technical')
  [ -n "$BIZ" ] && ok "OBS-001 is a business signal" || warn "No business signal in OBS-001 - what number would the client phone you about? (/observability-spec)"
  if echo "$TEC" | grep -qE 'NFR-[0-9]{3}' && ! echo "$TEC" | grep -q 'NFR-0nn'; then ok "OBS-002 is a technical signal that quotes an NFR"
  else warn "OBS-002 does not quote an NFR row - p95 against which number the client agreed?"; fi
  if [ -n "$METRIC" ] && grep -qF "$METRIC" "$OS"; then ok "The spec names the metric the pipeline checks: $METRIC"
  else warn "OBS_BUSINESS_METRIC in ci/production.yml (${METRIC:-unset}) is not named in the spec"; fi
  [ -n "$BIZ" ] && echo "$TEC" | grep -qE 'NFR-[0-9]{3}' && OBS_SPEC_OK=yes
else warn "No specs/design/observability.md - Session 17: /observability-spec writes it"; fi

# --- 6. Instrumentation ------------------------------------------------------------------------
hdr "6 - The code is instrumented - telemetry, the business metric, X-Request-Id"
INSTR_OK=no; TEL=no; MET=no; RID=no
code -qE 'configure_azure_monitor|useAzureMonitor|applicationinsights-agent' && { ok "Telemetry to Application Insights (the distro or the agent), on only when configured"; TEL=yes; } || warn "No Application Insights instrumentation - stacks.md, section 5"
if [ -n "$METRIC" ] && code -qF "$METRIC"; then ok "The code creates the business metric $METRIC"; MET=yes
else warn "The code does not create ${METRIC:-the business metric} - a counter, in the use case (stacks.md, section 6)"; fi
code -qi 'X-Request-Id' && { ok "Every response carries X-Request-Id"; RID=yes; } || warn "No X-Request-Id - stacks.md, section 7"
code -q 'DRILL_SLOW_MS' && ok "The drill switch is in the code" || warn "No drill switch (DRILL_SLOW_MS, DRILL_ERROR_PCT) - stacks.md, section 8"
NOBS=$(tests -hiE '(def |test\(|it\(|void |@DisplayName\(.)[^(]*obs[_-]?[0-9]{3}' | wc -l | tr -d ' ')
[ "$NOBS" -ge 1 ] && ok "$NOBS test(s) named after an OBS signal - the metric is read back" || warn "No test named OBS-0nn - a metric no test covers drifts silently"
[ "$TEL" = yes ] && [ "$MET" = yes ] && [ "$RID" = yes ] && INSTR_OK=yes

# --- 7. The stack in Azure -----------------------------------------------------------------------
hdr "7 - The stack in Terraform - Application Insights, the dashboard, alerts"
STACK_OK=no
if [ -f "$INF/observability.tf" ]; then
  OT="$(flat "$INF/observability.tf")"; ok "infra/observability.tf"
  N=0
  echo "$OT" | grep -q 'resource "azurerm_application_insights"' && { ok "Application Insights, on the Log Analytics workspace"; N=$((N+1)); } || warn "No azurerm_application_insights"
  echo "$OT" | grep -q 'resource "azurerm_application_insights_workbook"' && { ok "A workbook - the dashboard with the business and technical tiles"; N=$((N+1)); } || warn "No workbook - where does the client's number show?"
  NA=$(echo "$OT" | grep -oE 'resource "azurerm_monitor_(scheduled_query_rules_alert_v2|metric_alert)"' | wc -l | tr -d ' ')
  [ "$NA" -ge 1 ] && { ok "$NA alert rule(s)"; N=$((N+1)); } || warn "No alert rules"
  echo "$OT" | grep -q 'resource "azurerm_monitor_action_group"' && { ok "An action group - someone hears about it"; N=$((N+1)); } || warn "No action group - an alert nobody receives"
  if flat "$INF/secrets.tf" | grep -q 'APPLICATIONINSIGHTS_CONNECTION_STRING'; then ok "The connection string reaches the app as a secret"; N=$((N+1))
  else warn "APPLICATIONINSIGHTS_CONNECTION_STRING is not in local.app_secrets - the app sends nothing (WORKSHOP-S17.md, step 1)"; fi
  [ "$N" -eq 5 ] && STACK_OK=yes
elif [ -f "$INF/observability.tf.s17" ]; then warn "infra/observability.tf.s17 is waiting - Session 17, step 1: rename it to observability.tf"
else warn "No infra/observability.tf - copy the lab's infra-additions/observability.tf (setup-production adds it)"; fi

# --- 8. The pipeline proves it -------------------------------------------------------------------
hdr "8 - The pipeline proves it - the telemetry check, the drill, the rollback"
PIPE_OK=no
if [ -f "$PY" ]; then
  [ "$(pvar OBSERVABILITY)" = on ] && ok "OBSERVABILITY is on - verify:observability is real" || warn "OBSERVABILITY is not \"on\" - verify:observability is still planned (Session 17, step 4)"
  MISSJ=""; JOBS=no; for j in verify:observability drill:slow drill:errors drill:clear rollback:test; do grep -qE "^$j:" "$PY" || MISSJ="$MISSJ $j"; done
  [ -z "$MISSJ" ] && { ok "verify:observability, the drill and rollback:test are in the pipeline"; JOBS=yes; } || warn "Missing from ci/production.yml:$MISSJ"
fi
echo "$R" | grep -qE 'obs\.version' && echo "$R" | grep -qE 'obs\.business' && ok "The strategy has obs.version and obs.business rows" || warn "No obs.version / obs.business rows - the scorecard ignores the telemetry"
if [ -f "$ST" ] && tr -d '\r' < "$ST" | sed -n '/^## 6\./,$p' | grep -q 'verify:dast' && tr -d '\r' < "$ST" | sed -n '/^## 6\./,$p' | grep -q 'verify:observability'; then ok "Section 6 of the strategy draws verify:dast and verify:observability"
else warn "Section 6 of the strategy does not show verify:dast and verify:observability yet"; fi
DRILL=no
if [ -f "$OS" ]; then
  DR=$(tr -d '\r' < "$OS" | sed -n '/[Tt]he drill/,$p' | grep -E '^\|[[:space:]]*(slow|errors)[[:space:]]*\|')
  if [ -n "$DR" ] && ! echo "$DR" | grep -qiE 'fill in|\|[[:space:]]*\|'; then ok "The drill is recorded: when each alert fired, and the request found by its id"; DRILL=yes
  else warn "The drill table in observability.md is not filled in - run it, then write down what happened"; fi
fi
[ "$(pvar OBSERVABILITY)" = on ] && [ "${JOBS:-no}" = yes ] && echo "$R" | grep -qE 'obs\.business' && [ "$DRILL" = yes ] && PIPE_OK=yes
TAGGED=no; git -C "$REPO" rev-parse -q --verify refs/tags/L6-production >/dev/null && TAGGED=yes

hdr "Ready for layer 7? (see BUILD-ROADMAP.md)"
MISS=0
bar() { if [ "$1" = "yes" ]; then echo "  ${C_G}[ HAVE ]${C_0} $2"; else echo "  ${C_R}[ NEED ]${C_0} $2"; MISS=$((MISS+1)); fi; }
bar $THREAT_OK "A threat model - every threat a control and a proof"
bar $SEC_OK "Controls tested, named after their threats"
bar $SECRETS_OK "Secrets from the environment, none in git"
bar $DAST_OK "The running service scanned after every deploy"
bar $OBS_SPEC_OK "An observability spec - one business, one technical signal"
bar $INSTR_OK "The code instrumented - telemetry, the business metric, X-Request-Id"
bar $STACK_OK "Application Insights, a dashboard and alerts, in Terraform"
bar $PIPE_OK "The pipeline checks the telemetry; the drill run and recorded"
bar $TAGGED "Tagged L6-production"
echo
[ "$MISS" -eq 0 ] && echo "  ${C_G}READY${C_0} - layer 6 is in. Safe to expose, and you can see it run." || echo "  ${C_Y}NOT YET${C_0} - $MISS item(s) above."

echo
echo "============================================================"
echo " ${C_G}ok: $PASS${C_0}   ${C_Y}warnings: $WARN${C_0}   ${C_R}failed: $FAIL${C_0}"
echo "============================================================"
if [ "$FAIL" -gt 0 ]; then echo " Something required is missing. Fix the [FAIL] lines and run again."; exit 1; fi
[ "$WARN" -gt 0 ] && echo " Nothing is broken. Read the warnings and decide - at the debrief you will be asked about them."
exit 0
