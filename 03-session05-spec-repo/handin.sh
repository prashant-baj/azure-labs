#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  handin.sh  -  Package a case repository for hand-in  (macOS / Linux / WSL)
#
#  For groups who cannot push to a remote yet. Produces ONE file containing the
#  full repository AND its commit history, which the facilitator can restore.
#  Use this only until hosting is sorted - a remote is better in every way.
#
#  USAGE
#    chmod +x handin.sh      # first time only
#    ./handin.sh <path-to-case-repo> [output-directory]
#
#  EXAMPLE
#    ./handin.sh ~/work/group-1 ~/Desktop
#
#  A PowerShell twin (handin.ps1) exists for native Windows.
# =============================================================================

set -uo pipefail

if [ -t 1 ]; then
  C_G=$'\033[0;32m'; C_R=$'\033[0;31m'; C_Y=$'\033[0;33m'; C_B=$'\033[0;36m'; C_0=$'\033[0m'
else C_G=""; C_R=""; C_Y=""; C_B=""; C_0=""; fi
ok()   { echo "  ${C_G}[ OK ]${C_0} $1"; }
warn() { echo "  ${C_Y}[WARN]${C_0} $1"; }
bad()  { echo "  ${C_R}[FAIL]${C_0} $1"; }
hdr()  { echo; echo "${C_B}==> $1${C_0}"; }

REPO="${1:-}"
OUT="${2:-.}"

echo "============================================================"
echo " Junior SWAT Labs - package case repository for hand-in"
echo "============================================================"

if [ -z "$REPO" ]; then
  bad "No repository given."
  echo "  Usage: ./handin.sh <path-to-case-repo> [output-directory]"
  exit 1
fi
[ -d "$REPO/.git" ] || { bad "$REPO is not a git repository."; exit 1; }
command -v git >/dev/null 2>&1 || { bad "Git is not installed."; exit 1; }

NAME="$(basename "$(cd "$REPO" && pwd)")"
STAMP="$(date +%Y%m%d)"
FILE="$OUT/${NAME}-${STAMP}.bundle"

hdr "Checking the repository"
DIRTY="$(git -C "$REPO" status --porcelain)"
if [ -n "$DIRTY" ]; then
  warn "Uncommitted changes - these will NOT be included:"
  echo "$DIRTY" | sed 's/^/        /'
  echo "        Commit them first, then run this again."
else
  ok "Working tree is clean"
fi
COMMITS="$(git -C "$REPO" rev-list --count HEAD 2>/dev/null || echo 0)"
ok "$COMMITS commits will be included"

hdr "Packaging"
mkdir -p "$OUT" || { bad "Cannot create $OUT"; exit 1; }
if git -C "$REPO" bundle create "$FILE" --all >/dev/null 2>&1; then
  ok "Created $FILE"
else
  bad "Bundle failed."; exit 1
fi

if git -C "$REPO" bundle verify "$FILE" >/dev/null 2>&1; then
  ok "Bundle verified"
else
  bad "Bundle did not verify - do not hand this in."; exit 1
fi

SIZE="$(ls -lh "$FILE" | awk '{print $5}')"
ok "Size $SIZE"

hdr "Hand it in"
cat <<TXT
  Send this one file to the facilitator by whatever your team already uses.
  It carries every commit, so the difference between version one and version
  two is still reviewable.

  To restore it later, anywhere:
     git clone $(basename "$FILE") $NAME

  When hosting is sorted, stop using this:
     git remote add origin <url> && git push -u origin main
TXT
echo
