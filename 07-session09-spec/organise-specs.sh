#!/usr/bin/env bash
# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  organise-specs.sh  -  Session 9: put the case repository into four layers
#                        (macOS / Linux / WSL)
#
#  What it does, once per group:
#    1. Moves the Module 2 files into specs/design/  (git mv - history is kept)
#    2. Adds constitution.md, specs/README.md and a first slice folder
#    3. Adds the Session 9 templates, prompts and Claude Code commands
#    4. Adds the Module 3 section to CLAUDE.md
#    5. Commits all of it as one commit
#
#  It never deletes anything, and never overwrites a file you have written.
#
#  USAGE
#    chmod +x organise-specs.sh            # first time only
#    ./organise-specs.sh <path-to-case-repo> [slice-name]
#    e.g. ./organise-specs.sh ~/work/group-1 status-with-source
#
#  A PowerShell twin (organise-specs.ps1) exists for native Windows.
# =============================================================================

set -uo pipefail

if [ -t 1 ]; then
  C_G=$'\033[0;32m'; C_R=$'\033[0;31m'; C_Y=$'\033[0;33m'; C_B=$'\033[0;36m'; C_0=$'\033[0m'
else C_G=""; C_R=""; C_Y=""; C_B=""; C_0=""; fi
ok()   { echo "  ${C_G}[ OK ]${C_0} $1"; }
warn() { echo "  ${C_Y}[WARN]${C_0} $1"; }
bad()  { echo "  ${C_R}[FAIL]${C_0} $1"; }
hdr()  { echo; echo "${C_B}==> $1${C_0}"; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${1:-}"
SLICE_RAW="${2:-first-slice}"

if [ -z "$REPO" ]; then
  echo "Usage: ./organise-specs.sh <path-to-case-repo> [slice-name]"; exit 1
fi
[ -d "$REPO" ] || { bad "Path not found: $REPO"; exit 1; }
REPO="$(cd "$REPO" && pwd)"

echo "============================================================"
echo " Junior SWAT Labs - Session 9 - organise the case repository"
echo " $REPO"
echo "============================================================"

hdr "Before we start"
if [ ! -d "$REPO/.git" ]; then bad "Not a git repository. Run 03-session05-spec-repo/new-case-repo first."; exit 1; fi
if [ ! -d "$REPO/specs" ]; then bad "No specs/ folder. Is this your case repository?"; exit 1; fi
if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  bad "You have uncommitted changes. Commit them first, so this step is one clean commit:"
  echo "      git -C \"$REPO\" add -A && git -C \"$REPO\" commit -m \"wip: before Session 9\""
  exit 1
fi
ok "Clean git repository"

# --- 1. Module 2 files into specs/design --------------------------------------
hdr "1 · Module 2 files into specs/design/"
mkdir -p "$REPO/specs/design"
for item in solution-definition.md integration-decisions.md nfr-register.md constraints.md contracts adr diagrams; do
  src="$REPO/specs/$item"; dst="$REPO/specs/design/$item"
  if [ -e "$dst" ]; then ok "design/$item already in place"
  elif [ -e "$src" ]; then
    if git -C "$REPO" ls-files --error-unmatch "specs/$item" >/dev/null 2>&1; then
      git -C "$REPO" mv "specs/$item" "specs/design/$item" && ok "moved $item"
    else
      mv "$src" "$dst" && ok "moved $item (was not yet committed)"
    fi
  else
    warn "$item not found - if your group never wrote it, say so in the debrief"
  fi
done
# Anything else left loose in specs/
for f in "$REPO"/specs/*; do
  name="$(basename "$f")"
  case "$name" in README.md|design|[0-9][0-9][0-9]-*) continue ;; esac
  warn "specs/$name left where it is - move it into design/ yourself if it belongs to the design record"
done

# --- 2. Constitution, index, first slice --------------------------------------
hdr "2 · Constitution, index and first slice"
if [ -f "$REPO/constitution.md" ]; then ok "constitution.md already exists - left alone"
else cp "$HERE/templates/constitution.md" "$REPO/constitution.md" && ok "constitution.md added"; fi

cp "$HERE/templates/specs-README.md" "$REPO/specs/README.md" && ok "specs/README.md now describes the four layers"

SLICE="$(echo "$SLICE_RAW" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
[ -n "$SLICE" ] || SLICE="first-slice"
EXISTING="$(find "$REPO/specs" -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' | sort | tail -1)"
if [ -n "$EXISTING" ] && [ -z "${2:-}" ]; then
  ok "Slice folder already exists: specs/$(basename "$EXISTING") - no new one created"
else
  LAST="$(basename "${EXISTING:-000-x}" | cut -c1-3)"
  NEXT="$(printf '%03d' $((10#$LAST + 1)))"
  DIR="$REPO/specs/$NEXT-$SLICE"
  mkdir -p "$DIR"
  SAFE="$(printf '%s' "$SLICE_RAW" | sed 's/[\/&]/\\&/g')"
  for t in spec plan tasks; do
    sed -e "s/<NNN>/$NEXT/g" -e "s/<slice name>/$SAFE/g" "$HERE/templates/$t.md" > "$DIR/$t.md"
  done
  ok "specs/$NEXT-$SLICE/ created with spec.md, plan.md, tasks.md"
fi

# --- 3. Templates, prompts, commands ------------------------------------------
hdr "3 · Templates, prompts and Claude Code commands"
mkdir -p "$REPO/templates" "$REPO/prompts" "$REPO/.claude/commands"
for t in constitution spec plan tasks; do
  if [ -f "$REPO/templates/$t.md" ]; then ok "templates/$t.md already exists - left alone"
  else cp "$HERE/templates/$t.md" "$REPO/templates/$t.md" && ok "templates/$t.md added"; fi
done
cp "$HERE/prompts/09-spec-driven.md" "$REPO/prompts/" && ok "prompts/09-spec-driven.md added"
N=0
for c in "$HERE"/claude-commands/*.md; do cp "$c" "$REPO/.claude/commands/"; N=$((N+1)); done
ok "$N commands added to .claude/commands/  (type /spec- in Claude Code)"

# --- 4. CLAUDE.md -------------------------------------------------------------
hdr "4 · CLAUDE.md"
if [ ! -f "$REPO/CLAUDE.md" ]; then
  warn "No CLAUDE.md - creating one with just the Module 3 section"
  cat "$HERE/templates/CLAUDE-module3.md" > "$REPO/CLAUDE.md"
elif grep -q "## Module 3 — working from the spec" "$REPO/CLAUDE.md"; then
  ok "Module 3 section already present"
else
  cat "$HERE/templates/CLAUDE-module3.md" >> "$REPO/CLAUDE.md" && ok "Module 3 section appended"
fi

# --- 5. Commit ----------------------------------------------------------------
hdr "5 · Commit"
git -C "$REPO" add -A
if git -C "$REPO" diff --cached --quiet; then
  ok "Nothing to commit - the repository was already organised"
else
  git -C "$REPO" commit -q -m "organise: four layers - design record, constitution, first slice, Session 9 commands" \
    && ok "Committed: $(git -C "$REPO" log -1 --pretty=%h) organise: four layers"
fi

echo
echo "============================================================"
echo " Done. Next:"
echo "   1. Write section 0 of the slice spec BY HAND, then commit it."
echo "   2. Open Claude Code in $REPO and type /spec-constitution"
echo "   3. Check your work any time:  ./check-spec.sh \"$REPO\""
echo "============================================================"
exit 0
