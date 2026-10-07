#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  connect-gitlab.sh  -  point the case repository at your group's GitLab
#                         project and push everything  (macOS / Linux / WSL)
#
#  USAGE
#    chmod +x connect-gitlab.sh             # first time only
#    ./connect-gitlab.sh <path-to-case-repo> <gitlab-project-url>
#    e.g. ./connect-gitlab.sh ~/work/group-1 https://gitlab.stackroute.in/mindsprint-group1/case-repo.git
#
#  Safe to run again: it updates the remote and pushes whatever is new.
#  A PowerShell twin (connect-gitlab.ps1) exists for native Windows.
# =============================================================================

set -uo pipefail
if [ -t 1 ]; then
  C_G=$'\033[0;32m'; C_R=$'\033[0;31m'; C_Y=$'\033[0;33m'; C_0=$'\033[0m'
else C_G=""; C_R=""; C_Y=""; C_0=""; fi
ok()   { echo "  ${C_G}[ OK ]${C_0} $1"; }
warn() { echo "  ${C_Y}[WARN]${C_0} $1"; }
bad()  { echo "  ${C_R}[FAIL]${C_0} $1"; }

REPO="${1:-}"; URL="${2:-}"
if [ -z "$REPO" ] || [ -z "$URL" ]; then
  echo "Usage: ./connect-gitlab.sh <path-to-case-repo> <gitlab-project-url>"; exit 1
fi
[ -d "$REPO/.git" ] || { bad "Not a git repository: $REPO"; exit 1; }

case "$URL" in
  https://gitlab.stackroute.in/*) ok "GitLab project URL looks right" ;;
  *) warn "This is not a gitlab.stackroute.in URL - continuing, but check it with the facilitator" ;;
esac
case "$URL" in *.git) ;; *) URL="$URL.git" ;; esac

if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  warn "You have uncommitted changes - they will NOT be pushed. Commit first if you want them on GitLab."
fi

if git -C "$REPO" remote get-url origin >/dev/null 2>&1; then
  OLD="$(git -C "$REPO" remote get-url origin)"
  if [ "$OLD" != "$URL" ]; then git -C "$REPO" remote set-url origin "$URL"; ok "Remote 'origin' changed from $OLD"
  else ok "Remote 'origin' already set"; fi
else
  git -C "$REPO" remote add origin "$URL"; ok "Remote 'origin' added"
fi

BR="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
echo
echo "  Pushing branch '$BR' and all tags. GitLab may ask for your username and a"
echo "  personal access token (not your password) - see the README if it does."
echo
LOG="$(mktemp)"
git -C "$REPO" push -u origin "$BR" >"$LOG" 2>&1; RC=$?
cat "$LOG"
if [ "$RC" -eq 0 ]; then
  git -C "$REPO" push origin --tags >>"$LOG" 2>&1 || warn "Branch pushed, but the tags did not go - run: git push origin --tags"
  echo; ok "Pushed. Your group's work is on GitLab."; rm -f "$LOG"; exit 0
fi

echo
bad "The push did not go through. What the message usually means:"
if grep -qiE 'certificate|SSL' "$LOG"; then
  echo "    Certificate problem - your company network inspects HTTPS. Run tools/fix-company-proxy.sh"
  echo "    from the root of azure-labs, open a new terminal, and run this again."
elif grep -qiE 'not found|does not appear to be a git repository' "$LOG"; then
  echo "    The project does not exist yet, or the URL is wrong. Only the IT team can create"
  echo "    projects in the mindsprint groups - ask the facilitator for the exact URL."
elif grep -qiE '403|not allowed|denied|protected branch' "$LOG"; then
  echo "    You can reach the project but may not push. Either you are not a member of it, or"
  echo "    '$BR' is a protected branch and your role is Developer. Ask IT for Maintainer on the"
  echo "    project, or to allow Developers to push to '$BR'."
elif grep -qiE '401|Authentication failed|HTTP Basic|invalid credentials' "$LOG"; then
  echo "    Login failed. GitLab over HTTPS needs a personal access token instead of your password:"
  echo "    GitLab > your avatar > Edit profile > Access tokens > scope 'write_repository'."
  echo "    Use your GitLab username and paste the token when asked for a password."
elif grep -qiE 'rejected|fetch first|non-fast-forward' "$LOG"; then
  echo "    GitLab already has commits you do not. Someone else pushed first. Run:"
  echo "      git -C \"$REPO\" pull --rebase origin $BR"
  echo "    then run this script again."
else
  echo "    Read the message above. If it is not obvious, show it to the facilitator."
fi
rm -f "$LOG"
echo
echo "  Your work is safe locally either way. If GitLab is not ready today, hand in a bundle:"
echo "    ../03-session05-spec-repo/handin.sh \"$REPO\" ~/Desktop"
exit 1
