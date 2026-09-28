# Tools · Behind a company proxy

Many company networks **inspect HTTPS traffic**: a proxy opens each secure connection, checks it,
and re-signs it with the company's own root certificate. Windows, macOS and your browser trust
that certificate because your IT team installed it. But the **Azure CLI, Git and Node/npm each
keep their own list of trusted certificates** and ignore the operating system's, so they fail
with errors like these:

| Tool | Error |
|------|-------|
| Azure CLI, pip | `[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: self-signed certificate in certificate chain` |
| Git | `SSL certificate problem: self-signed certificate in certificate chain` / `unable to get local issuer certificate` |
| npm, Node | `SELF_SIGNED_CERT_IN_CHAIN` / `UNABLE_TO_GET_ISSUER_CERT_LOCALLY` |

`fix-company-proxy` teaches those tools to trust **exactly what your machine already trusts**.
You do not need IT or admin rights, and no security check is switched off.

`00-access-check` and `02-azure-resources-test` run it for you. Run it yourself if Git or npm
shows one of the errors above in any other lab.

## Run it

**Windows:** double-click **`fix-company-proxy.cmd`** in this folder. It works even where your
company blocks PowerShell scripts.

**macOS / Linux / WSL:**
```bash
chmod +x fix-company-proxy.sh    # first time only
./fix-company-proxy.sh
```

Then **open a new terminal window**. Settings made for your user only reach windows opened
afterwards.

On a network that does not inspect HTTPS it says *no certificate changes needed* and changes
nothing.

## What it changes

It changes something only when it sees the certificate error. Every change is user-level.

| Change | Windows | macOS / Linux / WSL | Used by |
|--------|---------|---------------------|---------|
| Certificate bundle | `%USERPROFILE%\.azure\ca-bundle.pem` | `~/.azure/ca-bundle.pem` | everything below |
| `REQUESTS_CA_BUNDLE` → the bundle | user environment variable | line in your shell profile | Azure CLI, pip, Python |
| `NODE_EXTRA_CA_CERTS` → the bundle | user environment variable | line in your shell profile | Node, npm |
| Git certificate setting | `git config --global http.sslBackend schannel` (Git uses Windows' own check) | `git config --global http.sslCAInfo <bundle>` | Git |

The bundle is the usual public certificate list plus the certificates your machine trusts. It
never includes a certificate Windows marks as distrusted.

It never overwrites a setting that already points somewhere else. It warns you and leaves it alone.

On Windows it also routes the Azure CLI and Terraform through your company proxy when Windows
has one configured. That applies only while the lab script runs.

## Why this is within company policy

- **Nothing is bypassed.** Your traffic still goes through the company proxy and is still inspected.
- **No new trust is added.** The tools trust what your machine already trusts, and nothing more.
- **User-level only.** No admin rights, no change to the machine's certificate store, and no edits
  to installed software.
- **These are the vendors' documented settings.** Microsoft documents `REQUESTS_CA_BUNDLE` for the
  Azure CLI, Node documents `NODE_EXTRA_CA_CERTS`, and Git for Windows documents `schannel`.

## Undo

**Windows:** double-click **`undo-company-proxy-fix.cmd`**. **macOS / Linux / WSL:**
`./fix-company-proxy.sh --undo`.

Undo reverses only what the script changed. It deletes the bundle, removes the environment
variables that point at it, removes the marked block from your shell profile, and unsets the Git
setting if the script added it.

## Do not "fix" the error these ways

These make the message go away, but they switch security off or go around the company proxy.
That breaks company policy:

- `AZURE_CLI_DISABLE_CONNECTION_VERIFICATION=1`, `NODE_TLS_REJECT_UNAUTHORIZED=0`,
  `npm config set strict-ssl false`, `git config http.sslVerify false`, `pip --trusted-host`, `curl -k`
- a mobile hotspot or personal VPN to avoid the company proxy
- installing certificates into the machine store, or editing files under `Program Files`

## If it still fails

| Symptom | What to do |
|---------|------------|
| "Still cannot connect securely" | Your machine may not hold the company certificate the usual way. Export it from the browser: open `https://management.azure.com` → padlock → *Certificate* → *Certification Path* → select the top entry → *View Certificate* → *Details* → *Copy to File* → **Base-64 (.CER)**. Append the file's contents to the bundle, then run the script again. |
| Git on Windows: `CRYPT_E_NO_REVOCATION_CHECK` | Your proxy blocks certificate-revocation lookups. Share the exact message with your facilitator. |
| `git push` or `npm install` hangs, then times out | That is the proxy address, not the certificate. Run `fix-company-proxy.cmd`. If it prints *Windows uses a proxy (…)*, then run `git config --global http.proxy <that address>` or `npm config set proxy <that address>`. Both still route through the company proxy. |
| A setting was "already set … left unchanged" | Someone, perhaps IT, set it before. Ask your facilitator before changing it. |
| `docker pull` or `docker build` fails with a certificate error | Docker Desktop uses the operating system's certificates, so this is rarely the cause. Behind a proxy, build in Azure with `az acr build` instead (see `02-azure-resources-test`). |
