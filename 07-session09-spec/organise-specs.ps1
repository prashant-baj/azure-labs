# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  organise-specs.ps1  -  Session 9: put the case repository into four layers
#                         (Windows PowerShell 5.1 / PowerShell 7)
#
#  What it does, once per group:
#    1. Moves the Module 2 files into specs\design\  (git mv - history is kept)
#    2. Adds constitution.md, specs\README.md and a first slice folder
#    3. Adds the Session 9 templates, prompts and Claude Code commands
#    4. Adds the Module 3 section to CLAUDE.md
#    5. Commits all of it as one commit
#
#  It never deletes anything, and never overwrites a file you have written.
#
#  USAGE
#    ./organise-specs.ps1 -Path "C:\work\group-1" [-Slice "status-with-source"]
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  A bash twin (organise-specs.sh) exists for macOS / Linux / WSL.
# =============================================================================
param(
  [Parameter(Mandatory=$true)][string]$Path,
  [string]$Slice = ""
)

function Ok($m)   { Write-Host "  [ OK ] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red }
function Hdr($m)  { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
$Utf8 = New-Object System.Text.UTF8Encoding $false
function ReadText($p)  { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }
function WriteText($p, $t) { [System.IO.File]::WriteAllText($p, $t, $Utf8) }

$Here = $PSScriptRoot
if (-not (Test-Path $Path)) { Bad "Path not found: $Path"; exit 1 }
$Repo = (Resolve-Path $Path).Path
$SliceGiven = ($Slice -ne "")
if (-not $SliceGiven) { $Slice = "first-slice" }

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - Session 9 - organise the case repository"
Write-Host " $Repo"
Write-Host "============================================================"

Hdr "Before we start"
if (-not (Test-Path (Join-Path $Repo ".git"))) { Bad "Not a git repository. Run 03-session05-spec-repo/new-case-repo first."; exit 1 }
if (-not (Test-Path (Join-Path $Repo "specs"))) { Bad "No specs folder. Is this your case repository?"; exit 1 }
$dirty = git -C $Repo status --porcelain
if ($dirty) {
  Bad "You have uncommitted changes. Commit them first, so this step is one clean commit:"
  Write-Host "      git -C `"$Repo`" add -A ; git -C `"$Repo`" commit -m `"wip: before Session 9`""
  exit 1
}
Ok "Clean git repository"

# --- 1. Module 2 files into specs\design --------------------------------------
Hdr "1 - Module 2 files into specs/design/"
$design = Join-Path $Repo "specs\design"
New-Item -ItemType Directory -Force -Path $design | Out-Null
foreach ($item in @("solution-definition.md","integration-decisions.md","nfr-register.md","constraints.md","contracts","adr","diagrams")) {
  $src = Join-Path $Repo "specs\$item"; $dst = Join-Path $design $item
  if (Test-Path $dst) { Ok "design/$item already in place" }
  elseif (Test-Path $src) {
    git -C $Repo ls-files --error-unmatch "specs/$item" 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { git -C $Repo mv "specs/$item" "specs/design/$item"; Ok "moved $item" }
    else { Move-Item $src $dst; Ok "moved $item (was not yet committed)" }
  }
  else { Warn "$item not found - if your group never wrote it, say so in the debrief" }
}
Get-ChildItem (Join-Path $Repo "specs") | ForEach-Object {
  if ($_.Name -ne "README.md" -and $_.Name -ne "design" -and $_.Name -notmatch '^\d{3}-') {
    Warn "specs/$($_.Name) left where it is - move it into design/ yourself if it belongs to the design record"
  }
}

# --- 2. Constitution, index, first slice --------------------------------------
Hdr "2 - Constitution, index and first slice"
$const = Join-Path $Repo "constitution.md"
if (Test-Path $const) { Ok "constitution.md already exists - left alone" }
else { Copy-Item (Join-Path $Here "templates\constitution.md") $const; Ok "constitution.md added" }

Copy-Item (Join-Path $Here "templates\specs-README.md") (Join-Path $Repo "specs\README.md") -Force
Ok "specs/README.md now describes the four layers"

$kebab = ($Slice.ToLower() -replace '[^a-z0-9]+','-').Trim('-')
if (-not $kebab) { $kebab = "first-slice" }
$existing = Get-ChildItem (Join-Path $Repo "specs") -Directory | Where-Object { $_.Name -match '^\d{3}-' } | Sort-Object Name | Select-Object -Last 1
if ($existing -and -not $SliceGiven) {
  Ok "Slice folder already exists: specs/$($existing.Name) - no new one created"
} else {
  $last = 0
  if ($existing) { $last = [int]$existing.Name.Substring(0,3) }
  $next = "{0:D3}" -f ($last + 1)
  $dir = Join-Path $Repo "specs\$next-$kebab"
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  foreach ($t in @("spec","plan","tasks")) {
    $txt = ReadText (Join-Path $Here "templates\$t.md")
    $txt = $txt.Replace("<NNN>", $next).Replace("<slice name>", $Slice)
    WriteText (Join-Path $dir "$t.md") $txt
  }
  Ok "specs/$next-$kebab/ created with spec.md, plan.md, tasks.md"
}

# --- 3. Templates, prompts, commands ------------------------------------------
Hdr "3 - Templates, prompts and Claude Code commands"
foreach ($d in @("templates","prompts",".claude\commands")) { New-Item -ItemType Directory -Force -Path (Join-Path $Repo $d) | Out-Null }
foreach ($t in @("constitution","spec","plan","tasks")) {
  $dst = Join-Path $Repo "templates\$t.md"
  if (Test-Path $dst) { Ok "templates/$t.md already exists - left alone" }
  else { Copy-Item (Join-Path $Here "templates\$t.md") $dst; Ok "templates/$t.md added" }
}
Copy-Item (Join-Path $Here "prompts\09-spec-driven.md") (Join-Path $Repo "prompts\") -Force
Ok "prompts/09-spec-driven.md added"
$n = 0
Get-ChildItem (Join-Path $Here "claude-commands\*.md") | ForEach-Object {
  Copy-Item $_.FullName (Join-Path $Repo ".claude\commands\") -Force; $n++
}
Ok "$n commands added to .claude/commands/  (type /spec- in Claude Code)"

# --- 4. CLAUDE.md -------------------------------------------------------------
Hdr "4 - CLAUDE.md"
$claude = Join-Path $Repo "CLAUDE.md"
$block = ReadText (Join-Path $Here "templates\CLAUDE-module3.md")
if (-not (Test-Path $claude)) {
  Warn "No CLAUDE.md - creating one with just the Module 3 section"
  WriteText $claude $block
} elseif ((ReadText $claude) -match '## Module 3 .{1,3} working from the spec') {
  Ok "Module 3 section already present"
} else {
  WriteText $claude ((ReadText $claude) + $block)
  Ok "Module 3 section appended"
}

# --- 5. Commit ----------------------------------------------------------------
Hdr "5 - Commit"
git -C $Repo add -A
git -C $Repo diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Ok "Nothing to commit - the repository was already organised" }
else {
  git -C $Repo commit -q -m "organise: four layers - design record, constitution, first slice, Session 9 commands"
  $h = git -C $Repo log -1 --pretty=%h
  Ok "Committed: $h organise: four layers"
}

Write-Host ""
Write-Host "============================================================"
Write-Host " Done. Next:"
Write-Host "   1. Write section 0 of the slice spec BY HAND, then commit it."
Write-Host "   2. Open Claude Code in $Repo and type /spec-constitution"
Write-Host "   3. Check your work any time:  ./check-spec.ps1 -Path `"$Repo`""
Write-Host "============================================================"
exit 0
