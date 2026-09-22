<#
=============================================================================
  MindSprint Junior SWAT Engineering Program 2026 - Labs
  check-prereqs.ps1  -  Local toolchain readiness check  (Windows / PowerShell)

  Verifies the tools the Azure labs need are installed locally and are a
  reasonable version. Run this BEFORE the Azure access check (00-access-check).

  USAGE
    ./check-prereqs.ps1

  If scripts are blocked:
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

  Exit code is non-zero if any REQUIRED tool is missing or too old.
  A bash twin (check-prereqs.sh) exists for macOS / Linux / WSL.
=============================================================================
#>
[CmdletBinding()] param()
$ErrorActionPreference = 'Continue'
$script:Pass = 0; $script:Warn = 0; $script:Fail = 0

function Ok   ($m){ Write-Host "  [ OK ] $m" -ForegroundColor Green;  $script:Pass++ }
function Warn ($m){ Write-Host "  [WARN] $m" -ForegroundColor Yellow; $script:Warn++ }
function Bad  ($m){ Write-Host "  [FAIL] $m" -ForegroundColor Red;    $script:Fail++ }
function Hdr  ($m){ Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }

function VerNum($t){ if($t -and ("$t" -match '(\d+)\.(\d+)(\.\d+)?')){ return $Matches[0] } return $null }
function Has($bin){ return [bool](Get-Command $bin -ErrorAction SilentlyContinue) }
function CheckVer($name,$v,$min){
  if(-not $v){ Ok "$name: installed (version unknown)"; return }
  $isOk = $true
  if($min){ try { $isOk = ([version]$v -ge [version]$min) } catch { $isOk = $true } }
  if($isOk){ Ok "$name: $v" } else { Warn "$name: $v installed - $min+ recommended" }
}

Write-Host "============================================================"
Write-Host " Junior SWAT Labs - local toolchain check"
Write-Host (" Windows PowerShell - " + (Get-Date))
Write-Host "============================================================"

# --- Required -------------------------------------------------------------
Hdr "Required tools"

# Azure CLI
if(Has 'az'){
  $v = $null; try { $v = (az version -o json 2>$null | ConvertFrom-Json).'azure-cli' } catch {}
  CheckVer "Azure CLI (az)" $v "2.60.0"
} else { Bad "Azure CLI (az): not installed  -> winget install -e --id Microsoft.AzureCLI" }

# Git
if(Has 'git'){ CheckVer "Git" (VerNum (git --version 2>$null)) "2.30.0" }
else { Bad "Git: not installed  -> https://git-scm.com/downloads" }

# Python
if(Has 'python'){ CheckVer "Python" (VerNum (python --version 2>&1)) "3.10.0" }
elseif(Has 'python3'){ CheckVer "Python" (VerNum (python3 --version 2>&1)) "3.10.0" }
else { Bad "Python 3: not installed  -> https://www.python.org/downloads/ (or: winget install -e --id Python.Python.3.12)" }

# Node.js
if(Has 'node'){ CheckVer "Node.js" (VerNum (node --version 2>$null)) "18.0.0" }
else { Bad "Node.js: not installed  -> https://nodejs.org/ (LTS)" }

# npm
if(Has 'npm'){ CheckVer "npm" (VerNum (npm --version 2>$null)) "9.0.0" }
else { Bad "npm: not installed (ships with Node.js)" }

# Docker
if(Has 'docker'){
  CheckVer "Docker" (VerNum (docker --version 2>$null)) "24.0.0"
  docker info 2>$null | Out-Null
  if($LASTEXITCODE -eq 0){ Ok "Docker daemon: running" }
  else { Warn "Docker daemon: not running - start Docker Desktop" }
} else { Bad "Docker: not installed  -> https://docs.docker.com/get-docker/" }

# Terraform
if(Has 'terraform'){ CheckVer "Terraform" (VerNum ((terraform version 2>$null) | Select-Object -First 1)) "1.6.0" }
else { Bad "Terraform: not installed  -> https://developer.hashicorp.com/terraform/install (or: winget install -e --id HashiCorp.Terraform)" }

# Helm
if(Has 'helm'){ CheckVer "Helm" (VerNum (helm version --short 2>$null)) "3.12.0" }
else { Bad "Helm: not installed  -> https://helm.sh/docs/intro/install/ (or: winget install -e --id Helm.Helm)" }

# --- Recommended ----------------------------------------------------------
Hdr "Recommended tools"

# kubectl (for AKS labs)
if(Has 'kubectl'){
  $kv = VerNum (kubectl version --client -o json 2>$null)
  if(-not $kv){ $kv = VerNum (kubectl version --client 2>$null) }
  CheckVer "kubectl" $kv "1.28.0"
} else { Warn "kubectl: not installed (needed for AKS labs)  -> https://kubernetes.io/docs/tasks/tools/" }

# Azure Functions Core Tools (for Functions labs)
if(Has 'func'){ CheckVer "Azure Functions Core Tools" (VerNum (func --version 2>$null)) "4.0.0" }
else { Warn "Azure Functions Core Tools (func): not installed (needed for Functions labs)  -> https://learn.microsoft.com/azure/azure-functions/functions-run-local" }

# --- Summary --------------------------------------------------------------
Write-Host ""
Write-Host "============================================================"
Write-Host " Result:  " -NoNewline
Write-Host "$script:Pass ok" -ForegroundColor Green -NoNewline
Write-Host "   " -NoNewline
Write-Host "$script:Warn warnings" -ForegroundColor Yellow -NoNewline
Write-Host "   " -NoNewline
Write-Host "$script:Fail failed" -ForegroundColor Red
if($script:Fail -eq 0){
  Write-Host " Required toolchain is ready. Next: run the Azure access check (00-access-check)." -ForegroundColor Green
} else {
  Write-Host " Install the missing required tools above, then re-run." -ForegroundColor Red
}
Write-Host "============================================================"
if($script:Fail -eq 0){ exit 0 } else { exit 1 }
