#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  new-case-repo.sh  -  Create a group's case repository  (macOS / Linux / WSL)
#
#  Copies the Session 5 template into a new folder, initialises git and makes
#  the first commit. Run once per GROUP, not per person.
#
#  USAGE
#    chmod +x new-case-repo.sh     # first time only
#    ./new-case-repo.sh <group-name> [target-directory]
#
#  EXAMPLE
#    ./new-case-repo.sh group-1 ~/work
#
#  A PowerShell twin (new-case-repo.ps1) exists for native Windows.
# =============================================================================

set -uo pipefail

if [ -t 1 ]; then
  C_G=$'\033[0;32m'; C_R=$'\033[0;31m'; C_Y=$'\033[0;33m'; C_B=$'\033[0;36m'; C_0=$'\033[0m'
else C_G=""; C_R=""; C_Y=""; C_B=""; C_0=""; fi
ok()   { echo "  ${C_G}[ OK ]${C_0} $1"; }
warn() { echo "  ${C_Y}[WARN]${C_0} $1"; }
bad()  { echo "  ${C_R}[FAIL]${C_0} $1"; }
hdr()  { echo; echo "${C_B}==> $1${C_0}"; }

GROUP="${1:-}"
TARGET="${2:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================================"
echo " Junior SWAT Labs - Session 5 - create case repository"
echo "============================================================"

if [ -z "$GROUP" ]; then
  bad "No group name given."
  echo "  Usage: ./new-case-repo.sh <group-name> [target-directory]"
  echo "  Example: ./new-case-repo.sh group-1 ~/work"
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  bad "Git is not installed. Run 01-prereqs-check first."
  exit 1
fi

DEST="$TARGET/$GROUP"

hdr "Creating $DEST"

if [ -e "$DEST" ]; then
  bad "$DEST already exists. Choose another name or remove it first."
  exit 1
fi

if [ ! -d "$SCRIPT_DIR/template" ]; then
  bad "Template folder not found next to this script."
  exit 1
fi

mkdir -p "$TARGET" || { bad "Cannot create $TARGET"; exit 1; }
cp -R "$SCRIPT_DIR/template" "$DEST" || { bad "Copy failed"; exit 1; }
ok "Template copied"

cp "$SCRIPT_DIR/template/templates/solution-definition.md" "$DEST/specs/solution-definition.md"
ok "specs/solution-definition.md created from the template"

hdr "Initialising git"
(
  cd "$DEST" || exit 1
  git init -q -b main 2>/dev/null || git init -q
  git add -A
  git -c user.name="${GIT_AUTHOR_NAME:-$GROUP}" \
      -c user.email="${GIT_AUTHOR_EMAIL:-$GROUP@example.invalid}" \
      commit -q -m "chore: case repository created from Session 5 lab template"
) && ok "First commit made" || warn "git init or first commit did not complete - check git config"

hdr "Next"
cat <<TXT
  1. cd $DEST
  2. Paste your four Module 1 artefacts into docs/
  3. Fill the glossary table in CLAUDE.md - the client's words
  4. Write specs/solution-definition.md as a group, BY HAND
  5. Commit it:  git commit -am "spec: solution definition v1"
  6. Only then run the prompts in prompts/
  7. Check yourself:  ./check-spec-repo.sh $DEST

  Add your remote when you have one:
     git remote add origin <url> && git push -u origin main
TXT
echo
