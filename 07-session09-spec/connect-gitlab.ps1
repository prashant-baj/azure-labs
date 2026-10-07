# =============================================================================
#  MindSprint Junior SWAT Engineering Program 2026 - Labs
#  connect-gitlab.ps1  -  point the case repository at your group's GitLab
#                          project and push everything  (Windows)
#
#  USAGE
#    ./connect-gitlab.ps1 -Path "C:\work\group-1" -Url "https://gitlab.stackroute.in/mindsprint-group1/case-repo.git"
#    If scripts are blocked:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
#  Safe to run again: it updates the remote and pushes whatever is new.
#  A bash twin (connect-gitlab.sh) exists for macOS / Linux / WSL.
# =============================================================================
param(
  [Parameter(Mandatory=$true)][string]$Path,
  [Parameter(Mandatory=$true)][string]$Url
)
function Ok($m)   { Write-Host "  [ OK ] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red }

if (-not (Test-Path (Join-Path $Path ".git"))) { Bad "Not a git repository: $Path"; exit 1 }
$Repo = (Resolve-Path $Path).Path

if ($Url -like "https://gitlab.stackroute.in/*") { Ok "GitLab project URL looks right" }
else { Warn "This is not a gitlab.stackroute.in URL - continuing, but check it with the facilitator" }
if (-not $Url.EndsWith(".git")) { $Url = "$Url.git" }

if (git -C $Repo status --porcelain) { Warn "You have uncommitted changes - they will NOT be pushed. Commit first if you want them on GitLab." }

$old = git -C $Repo remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0 -and $old) {
  if ($old -ne $Url) { git -C $Repo remote set-url origin $Url; Ok "Remote 'origin' changed from $old" }
  else { Ok "Remote 'origin' already set" }
} else {
  git -C $Repo remote add origin $Url; Ok "Remote 'origin' added"
}

$br = git -C $Repo rev-parse --abbrev-ref HEAD
Write-Host ""
Write-Host "  Pushing branch '$br' and all tags. GitLab may ask for your username and a"
Write-Host "  personal access token (not your password) - see the README if it does."
Write-Host ""
$log = (& git -C $Repo push -u origin $br 2>&1 | Out-String)
$rc = $LASTEXITCODE
Write-Host $log
if ($rc -eq 0) {
  git -C $Repo push origin --tags 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { Warn "Branch pushed, but the tags did not go - run: git push origin --tags" }
  Write-Host ""; Ok "Pushed. Your group's work is on GitLab."; exit 0
}

Write-Host ""
Bad "The push did not go through. What the message usually means:"
if ($log -match 'certificate|SSL') {
  Write-Host "    Certificate problem - your company network inspects HTTPS. Run tools\fix-company-proxy.cmd"
  Write-Host "    from the root of azure-labs, open a new terminal, and run this again."
} elseif ($log -match 'not found|does not appear to be a git repository') {
  Write-Host "    The project does not exist yet, or the URL is wrong. Only the IT team can create"
  Write-Host "    projects in the mindsprint groups - ask the facilitator for the exact URL."
} elseif ($log -match '403|not allowed|denied|protected branch') {
  Write-Host "    You can reach the project but may not push. Either you are not a member of it, or"
  Write-Host "    '$br' is a protected branch and your role is Developer. Ask IT for Maintainer on the"
  Write-Host "    project, or to allow Developers to push to '$br'."
} elseif ($log -match '401|Authentication failed|HTTP Basic|invalid credentials') {
  Write-Host "    Login failed. GitLab over HTTPS needs a personal access token instead of your password:"
  Write-Host "    GitLab > your avatar > Edit profile > Access tokens > scope 'write_repository'."
  Write-Host "    Use your GitLab username and paste the token when asked for a password."
} elseif ($log -match 'rejected|fetch first|non-fast-forward') {
  Write-Host "    GitLab already has commits you do not. Someone else pushed first. Run:"
  Write-Host "      git -C `"$Repo`" pull --rebase origin $br"
  Write-Host "    then run this script again."
} else {
  Write-Host "    Read the message above. If it is not obvious, show it to the facilitator."
}
Write-Host ""
Write-Host "  Your work is safe locally either way. If GitLab is not ready today, hand in a bundle:"
Write-Host "    ..\03-session05-spec-repo\handin.ps1 -Path `"$Repo`" -Out `"$HOME\Desktop`""
exit 1
