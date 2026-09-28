<#
=============================================================================
  MindSprint Junior SWAT Engineering Program 2026 - Labs
  tools/fix-company-proxy.ps1   (Windows)

  Makes the Azure CLI, Git and Node/npm work on a company network that
  inspects HTTPS traffic - without switching any security check off.

  Such a network re-signs every website's certificate with the company's own
  root certificate. Windows trusts that certificate because your IT team
  installed it, but the Azure CLI, Git and Node each keep their own list of
  trusted certificates and ignore Windows'. This script teaches them to trust
  exactly what Windows already trusts - no more, no less.

  Start it with   fix-company-proxy.cmd        (check, and fix only if needed)
                  undo-company-proxy-fix.cmd   (reverse every change it made)
  00-access-check and 02-azure-resources-test run the check for you.

  What it changes - only when your network inspects HTTPS; user-level only,
  no admin rights, nothing installed:
    * writes %USERPROFILE%\.azure\ca-bundle.pem: the usual public
      certificates plus the ones Windows trusts (never one Windows distrusts)
    * REQUESTS_CA_BUNDLE  (your user)  -> Azure CLI, pip and Python use it
    * NODE_EXTRA_CA_CERTS (your user)  -> Node and npm use it
    * git config --global http.sslBackend schannel
                                       -> Git checks certificates the Windows way
  Variables that are already set to something else are left alone.
=============================================================================
#>
# No param() block: this file is run as commands (Get-Content | Invoke-Expression)
# so a company PowerShell execution policy cannot block it.
#   $ProxyFix = 'auto' (default) | 'force' | 'undo'   - set before running it
#   $ProxyFixNoRun = $true   - only define Invoke-CompanyProxyFix (used by the labs)

function Invoke-CompanyProxyFix {
  param([string]$Action = 'auto')
  $ErrorActionPreference = 'Continue'

  function PfOk  ($t) { Write-Host "  [ OK ] $t" -ForegroundColor Green }
  function PfWrn ($t) { Write-Host "  [WARN] $t" -ForegroundColor Yellow }
  function PfBad ($t) { Write-Host "  [FAIL] $t" -ForegroundColor Red }
  function PfSay ($t) { Write-Host "         $t" }

  $userHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
  $dir      = Join-Path $userHome '.azure'
  $bundle   = Join-Path $dir 'ca-bundle.pem'
  $record   = Join-Path $dir 'ca-bundle-changes.txt'   # what we changed, so undo reverses only that
  $vars     = 'REQUESTS_CA_BUNDLE', 'NODE_EXTRA_CA_CERTS'
  $hasGit   = [bool](Get-Command git -ErrorAction SilentlyContinue)

  # ---------------------------------------------------------------- undo ----
  if ($Action -eq 'undo') {
    foreach ($v in $vars) {
      if ([Environment]::GetEnvironmentVariable($v, 'User') -eq $bundle) {
        [Environment]::SetEnvironmentVariable($v, $null, 'User')
        Remove-Item "env:$v" -ErrorAction SilentlyContinue
        PfOk "Removed $v"
      }
    }
    $changes = if (Test-Path $record) { @(Get-Content $record) } else { @() }
    if ($hasGit -and ($changes -contains 'git http.sslBackend') -and ((git config --global --get http.sslBackend) -eq 'schannel')) {
      git config --global --unset http.sslBackend
      PfOk 'Removed git http.sslBackend'
    }
    foreach ($f in $bundle, $record) { if (Test-Path $f) { Remove-Item $f -Force } }
    PfOk 'Undone - Azure CLI, Git and Node are back to their own certificate lists'
    return $true
  }

  # --------------------------------------------- company proxy (this run) ----
  # az and terraform read HTTPS_PROXY; set it from the Windows settings if
  # Windows sends web traffic through a proxy. This window only.
  $target = [Uri]'https://management.azure.com'
  if ($env:HTTPS_PROXY) {
    PfOk "Using the proxy already set in HTTPS_PROXY ($env:HTTPS_PROXY)"
  } else {
    try {
      $p = [Net.WebRequest]::GetSystemWebProxy().GetProxy($target)
      if ($p -and $p.Host -ne $target.Host) {
        $env:HTTPS_PROXY = $p.AbsoluteUri.TrimEnd('/')
        $env:HTTP_PROXY  = $env:HTTPS_PROXY
        if (-not $env:NO_PROXY) { $env:NO_PROXY = 'localhost,127.0.0.1' }
        PfOk "Windows uses a proxy ($env:HTTPS_PROXY) - the Azure CLI and Terraform will use it too"
      } else {
        PfOk 'No explicit proxy configured'
      }
    } catch { PfWrn 'Could not read the Windows proxy settings - continuing without them' }
  }

  # ----------------------------------------------------- how to test ----
  # The Azure CLI's own Python is the best test: it is exactly what fails.
  # If the Azure CLI is not installed, Node (which also keeps its own list) will do.
  $py = (Get-ChildItem 'C:\Program Files*\Microsoft SDKs\Azure\CLI2\python.exe' -ErrorAction SilentlyContinue |
         Select-Object -First 1).FullName
  if (-not $py -and (Get-Command az -ErrorAction SilentlyContinue)) {
    $verLine = (az --version 2>$null) | Where-Object { $_ -match "^Python location '(.+)'" } | Select-Object -First 1
    if ($verLine -and ($verLine -match "^Python location '(.+)'")) { $py = $Matches[1] }
  }
  $hasNode = [bool](Get-Command node -ErrorAction SilentlyContinue)
  $script:pfDetail = ''

  function Test-SecureReach {
    if ($py) {
      $out = & $py -c "import requests; requests.get('https://management.azure.com', timeout=20)" 2>&1 | Out-String
      if ($LASTEXITCODE -eq 0) { return 'ok' }
      $script:pfDetail = ($out.Trim() -split "`n" | Select-Object -Last 1)
      if ($out -match 'CERTIFICATE_VERIFY_FAILED') { return 'untrusted' }
      return 'neterror'
    }
    if ($hasNode) {
      $js = "var r=require('https').get('https://management.azure.com',function(){process.exit(0)});" +
            "r.on('error',function(e){console.log(e.code||e.message);process.exit(1)});" +
            "r.setTimeout(20000,function(){console.log('TIMEOUT');process.exit(1)})"
      $out = & node -e $js 2>&1 | Out-String
      if ($LASTEXITCODE -eq 0) { return 'ok' }
      $script:pfDetail = $out.Trim()
      if ($out -match 'SELF_SIGNED_CERT_IN_CHAIN|UNABLE_TO_GET_ISSUER_CERT|UNABLE_TO_VERIFY_LEAF_SIGNATURE|CERT_UNTRUSTED') { return 'untrusted' }
      return 'neterror'
    }
    return 'unknown'
  }

  # ------------------------------------------- point the tools at the bundle ----
  function Set-ToolTrust {
    New-Item -ItemType Directory -Force $dir | Out-Null
    foreach ($v in $vars) {
      $cur = [Environment]::GetEnvironmentVariable($v, 'User')
      if (-not $cur) {
        [Environment]::SetEnvironmentVariable($v, $bundle, 'User')
        PfOk "$v set for your user"
      } elseif ($cur -ne $bundle) {
        PfWrn "$v is already set to $cur - left unchanged"
        if ($v -ne 'REQUESTS_CA_BUNDLE') { continue }
        PfSay 'Using the new bundle for this run only. If the Azure CLI fails in a new window, remove that setting.'
      }
      Set-Item "env:$v" $bundle
    }
    if ($hasGit) {
      $backend = git config --global --get http.sslBackend
      $cainfo  = git config --global --get http.sslCAInfo
      if ($backend -eq 'schannel') {
        PfOk 'Git already checks certificates the Windows way'
      } elseif (-not $backend -and -not $cainfo) {
        git config --global http.sslBackend schannel
        if (-not ((Test-Path $record) -and (@(Get-Content $record) -contains 'git http.sslBackend'))) {
          Add-Content -Path $record -Value 'git http.sslBackend'
        }
        PfOk 'Git now checks certificates the Windows way (http.sslBackend schannel)'
      } else {
        PfWrn "Git already has its own certificate setting (sslBackend=$backend sslCAInfo=$cainfo) - left unchanged"
      }
    }
  }

  # ---------------------------------------------------------------- check ----
  $state = Test-SecureReach
  $inUse = ($env:REQUESTS_CA_BUNDLE -eq $bundle) -and (Test-Path $bundle)

  if ($Action -ne 'force') {
    switch ($state) {
      'ok' {
        if ($inUse) { PfOk 'Secure connections work, using your certificate bundle'; Set-ToolTrust }
        else        { PfOk 'Secure connections to Azure work - no certificate changes needed' }
        return $true
      }
      'neterror' {
        PfWrn 'Could not reach Azure - not a certificate problem. The next step will show the error.'
        if ($script:pfDetail) { PfSay $script:pfDetail }
        return $true
      }
      'unknown' {
        PfWrn 'Could not test certificates - neither the Azure CLI nor Node is installed'
        return $true
      }
    }
    PfSay 'Your network inspects HTTPS traffic, and your tools do not yet trust your'
    PfSay 'company''s certificate. Teaching them to trust what Windows already trusts...'
  } else {
    PfSay 'Building the certificate bundle (forced)...'
  }

  # ---------------------------------------------------------- build bundle ----
  New-Item -ItemType Directory -Force $dir | Out-Null
  $lines = New-Object System.Collections.Generic.List[string]

  # 1. The usual public certificates - from the Azure CLI, or else from Node.
  $public = $false
  if ($py) {
    $certifi = (& $py -c 'import certifi; print(certifi.where())' 2>$null | Select-Object -First 1)
    if (-not $certifi) { $certifi = Join-Path (Split-Path $py) 'Lib\site-packages\certifi\cacert.pem' }
    if ($certifi -and (Test-Path $certifi)) { foreach ($l in (Get-Content $certifi)) { $lines.Add($l) }; $public = $true }
  }
  if (-not $public -and $hasNode) {
    $roots = & node -e 'process.stdout.write(require(''tls'').rootCertificates.join(''\n''))' 2>$null
    if ($LASTEXITCODE -eq 0 -and $roots) { foreach ($l in $roots) { $lines.Add($l) }; $public = $true }
  }
  if (-not $public) { PfWrn 'No public certificate list found - using only the certificates Windows holds' }

  # 2. Every certificate Windows trusts - never anything Windows distrusts.
  $distrusted = @{}
  Get-ChildItem 'Cert:\LocalMachine\Disallowed', 'Cert:\CurrentUser\Disallowed' -ErrorAction SilentlyContinue |
    ForEach-Object { $distrusted[$_.Thumbprint] = $true }
  $seen = @{}; $added = 0
  foreach ($store in 'Cert:\LocalMachine\Root', 'Cert:\CurrentUser\Root', 'Cert:\LocalMachine\CA', 'Cert:\CurrentUser\CA') {
    Get-ChildItem $store -ErrorAction SilentlyContinue | ForEach-Object {
      if ($_.NotAfter -lt (Get-Date)) { return }
      if ($seen.ContainsKey($_.Thumbprint) -or $distrusted.ContainsKey($_.Thumbprint)) { return }
      $seen[$_.Thumbprint] = $true
      $b64 = [Convert]::ToBase64String($_.RawData)
      $lines.Add('-----BEGIN CERTIFICATE-----')
      for ($i = 0; $i -lt $b64.Length; $i += 64) { $lines.Add($b64.Substring($i, [Math]::Min(64, $b64.Length - $i))) }
      $lines.Add('-----END CERTIFICATE-----')
      $added++
    }
  }
  Set-Content -Path $bundle -Value $lines -Encoding Ascii
  PfOk "Wrote $bundle ($added certificates from Windows)"

  Set-ToolTrust

  # ---------------------------------------------------------------- re-test ----
  $state = Test-SecureReach
  if ($state -eq 'ok') {
    PfOk 'Fixed - your tools now trust what Windows trusts'
    return $true
  }
  if ($state -eq 'unknown') { return $true }
  PfBad 'Still cannot connect securely. See "Behind a company proxy" in tools\README.md'
  if ($script:pfDetail) { PfSay $script:pfDetail }
  return $false
}

if (-not $ProxyFixNoRun) {
  $pfAction = if ($ProxyFix) { $ProxyFix } else { 'auto' }
  Write-Host '============================================================'
  Write-Host " Junior SWAT Labs - company proxy and certificates ($pfAction)"
  Write-Host '============================================================'
  $pfResult = Invoke-CompanyProxyFix -Action $pfAction | Select-Object -Last 1
  Write-Host ''
  if ($pfResult -and $pfAction -ne 'undo') {
    Write-Host ' If anything changed above, open a NEW terminal window so your tools pick it up.'
  }
}
