# Prerequisites · Local Toolchain Check

Confirms the tools the Azure labs need are installed on your machine and are a recent
enough version. It only inspects your local setup — it makes no network or Azure calls.

## Where this fits

The environment checks, in order:

1. **`00-access-check`** — can you reach the Azure lab account?
2. **`01-prereqs-check`** (this folder) — are the local tools installed?
3. **`02-azure-resources-test`** — does the full serverless stack deploy?

Tip: the Azure CLI checked here is also what `00-access-check` needs, so on a fresh machine
install the tools from the list below first.

## How to run

### Windows

Easiest — run **`check-prereqs.cmd`** (double-click it, or run `.\check-prereqs.cmd`). It runs the
check *without executing a `.ps1` file*, so a corporate PowerShell **execution policy** (even one
set by Group Policy) won't block it.

From a terminal in this folder you can also run:

```powershell
Get-Content .\check-prereqs.ps1 -Raw | Invoke-Expression
```

Running `.\check-prereqs.ps1` directly also works if your machine allows script execution. If a
downloaded file is flagged "blocked", clear it first with `Unblock-File .\check-prereqs.ps1`.

### macOS / Linux / WSL (bash)

```bash
cd path/to/azure-labs/01-prereqs-check
chmod +x check-prereqs.sh    # first time only
./check-prereqs.sh
```

Each tool reports `[ OK ]`, `[WARN]` (installed but old, or an optional tool missing), or
`[FAIL]` (a required tool missing). The script exits non-zero if anything required is
missing, and ends with an `ok / warnings / failed` summary.

## What it checks

### Required

| Tool | Min recommended | Install |
|------|-----------------|---------|
| **Azure CLI** (`az`) | 2.60 | `winget install -e --id Microsoft.AzureCLI` · macOS `brew install azure-cli` |
| **Git** | 2.30 | <https://git-scm.com/downloads> |
| **Python** | 3.10 | <https://www.python.org/downloads/> · `winget install -e --id Python.Python.3.12` |
| **Node.js** (+ npm) | 18 (LTS) | <https://nodejs.org/> |
| **Docker** | 24 | <https://docs.docker.com/get-docker/> — Docker Desktop must be **running** |
| **Terraform** | 1.6 | `winget install -e --id HashiCorp.Terraform` · macOS `brew install terraform` |
| **Helm** | 3.12 | `winget install -e --id Helm.Helm` · macOS `brew install helm` |

### Recommended (needed for specific labs)

| Tool | Min | Needed for |
|------|-----|-----------|
| **kubectl** | 1.28 | AKS / Kubernetes labs |
| **Azure Functions Core Tools** (`func`) | 4.0 | Azure Functions labs |

## Notes

- **Docker "daemon not running" warning:** Docker is installed but Docker Desktop (or the
  `docker` service) isn't started. Start it, then re-run — the labs need a running daemon
  to build/run containers.
- **Version below the minimum** is a warning, not a hard stop — the labs will likely still
  work, but upgrading is recommended. Each tool has its own upgrade command
  (e.g. `az upgrade`).
- The minimums are conservative baselines, not "latest". Newer versions are fine.
