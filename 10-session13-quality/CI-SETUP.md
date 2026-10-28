# Set up CI — on your laptop and in your GitLab pipeline

The same checks run in two places. On **your laptop** you find problems first, in seconds. In the **GitLab
pipeline** nobody can skip them. This page takes your group's **own case repository** from "a few jobs" to the
baseline quality pipeline, with exactly the same checks running locally.

| Check | On your laptop | In the pipeline (job) | Blocks the merge |
|---|---|---|---|
| Format and lint | ruff · Prettier + ESLint · Spotless + Checkstyle | `qa:lint` | yes |
| Complexity | lizard | `qa:complexity` | ratchet |
| Secrets | gitleaks | `qa:secrets` | yes |
| Static analysis (SAST) | semgrep | `qa:sast` | on ERROR |
| Dependencies | osv-scanner | `qa:dependencies` | yes |
| Infrastructure (if `infra/`) | checkov | `qa:iac` | ratchet |
| Unit tests | pytest · `npm test` · `mvn test` | your `test` job | yes |
| Scenarios | pytest-bdd · cucumber-js · Cucumber-JVM | `scenarios` | yes |

Below, `~/work/group-1` is your case repo and `<lab>` is this folder (`azure-labs/10-session13-quality`).
Use your own paths. Where your code sits in a sub-folder (`backend/`, `code/`), that folder is your
**app folder** — run the stack commands from there.

---

## 0 · Install — before the session (15 minutes)

**Your stack only:**

| Stack | Install | Check |
|---|---|---|
| Python | Python 3.12 (3.10 or later) | `python --version` |
| Node / TypeScript | Node.js 22 (20 or later) | `node --version` · `npm --version` |
| Java | JDK 21 and Maven 3.9 | `java -version` · `mvn -v` |

**The scanners — at least two laptops per group.** The Python-based ones install the same way everywhere:

```bash
python -m pip install --user "ruff==0.17.2" "lizard==1.24.2" "checkov==3.3.30"     # checkov only if you have infra/
```

| Tool | macOS | Linux / WSL | Windows (PowerShell) |
|---|---|---|---|
| gitleaks 8.21.2 | `brew install gitleaks` | release `gitleaks_8.21.2_linux_x64.tar.gz` → `~/.local/bin` | see below |
| osv-scanner 2.2.4 | `brew install osv-scanner` | release `osv-scanner_linux_amd64` → `~/.local/bin` | see below |
| semgrep 1.182.1 | `python -m pip install --user semgrep==1.182.1` | the same | in WSL, or Docker (below) |

**Windows — gitleaks and osv-scanner**, once, in PowerShell:

```powershell
New-Item -ItemType Directory -Force C:\tools | Out-Null
Invoke-WebRequest https://github.com/gitleaks/gitleaks/releases/download/v8.21.2/gitleaks_8.21.2_windows_x64.zip -OutFile $env:TEMP\gitleaks.zip
Expand-Archive $env:TEMP\gitleaks.zip -DestinationPath C:\tools -Force
Invoke-WebRequest https://github.com/google/osv-scanner/releases/download/v2.2.4/osv-scanner_windows_amd64.exe -OutFile C:\tools\osv-scanner.exe
[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path','User') + ';C:\tools', 'User')
# close and reopen the terminal, then:
gitleaks version; osv-scanner --version
```

**Windows — semgrep** with Docker Desktop instead of WSL, from your repo folder:

```powershell
docker run --rm -v "${PWD}:/src" semgrep/semgrep:1.182.1 semgrep scan --config p/default --metrics off --exclude specs --exclude .claude /src
```

Check what you have — anything missing is reported as *skipped* by `quality-local`, and the pipeline runs it anyway:

```bash
ruff --version; lizard --version; gitleaks version; semgrep --version; osv-scanner --version; checkov --version
```

---

## 1 · Lint configuration — once per repo (10 minutes)

`qa:lint` runs your stack's linter **with your repo's configuration**. No configuration, no gate — or a
red job on day one for the wrong reason. Ready-made, tested configurations are in [`lint-config/`](lint-config/).
Set the complexity limit to the number in **your** rule E-003, in the config **and** in `QA_COMPLEXITY_LIMIT`.

### Python — ruff

```bash
cp <lab>/lint-config/python/ruff.toml ~/work/group-1/<app folder>/
cd ~/work/group-1/<app folder>
ruff format .            # reformat - review the diff, it is only whitespace and quotes
ruff check --fix .       # safe fixes; what is left is your first triage list
```

Already have `[tool.ruff]` in `pyproject.toml`? Merge the settings there instead — `ruff.toml` wins if both exist.

### Node / TypeScript — Prettier and ESLint

```bash
cd ~/work/group-1/<app folder>
npm install --save-dev --save-exact eslint@9.39.5 @eslint/js@9.39.5 globals@16.5.0 prettier@3.6.2
cp <lab>/lint-config/node/eslint.config.mjs <lab>/lint-config/node/.prettierrc.json <lab>/lint-config/node/.prettierignore .
npx prettier --write .   # reformat - review the diff
npx eslint .             # what is left is your first triage list
```

- **TypeScript:** also `npm install --save-dev --save-exact typescript@5.9.3 typescript-eslint@8.72.1`, and use
  `lint-config/node/eslint.config.typescript.mjs`, renamed to `eslint.config.mjs`.
- **Browser code (React, Vue):** in the config, `globals.node` → `{ ...globals.browser, ...globals.node }`.
- **Commit `package-lock.json`.** The pipeline runs `npm ci`, which refuses to run without it.
- `.prettierignore` leaves Markdown, YAML, `specs/` and `infra/` alone — Prettier would rewrite your spec tables.

### Java — Spotless and Checkstyle

1. Paste the two `<plugin>` blocks from `lint-config/java/pom-plugins.xml` inside `<build><plugins>` of your `pom.xml`.
2. Copy `lint-config/java/checkstyle.xml` next to your `pom.xml`.

```bash
cd ~/work/group-1/<app folder>
mvn spotless:apply                     # reformat - review the diff
mvn -q checkstyle:check                # what is left is your first triage list
```

**Commit the configuration on its own**, before fixing anything: `chore: lint configuration (E-003, E-006, E-010)`.
Then the formatting commit: `style: format with <tool>`. Never switch a rule off to make it pass — triage it (step 3 of the README).

---

## 2 · Local CI — the loop before every push

From your **app folder**, every time before you push:

| Stack | Format | Lint | Unit tests and scenarios |
|---|---|---|---|
| Python | `ruff format --check .` | `ruff check .` | `python -m pytest -q` — runs `tests/step_defs` too |
| Node | `npx prettier --check .` | `npx eslint .` | `npm test` · then `npx cucumber-js` |
| Java | `mvn -q spotless:check` | `mvn -q checkstyle:check` | `mvn test` — runs `RunScenariosTest` too |

Then the scanners, from the lab folder, on the whole repo:

```bash
./quality-local.sh ~/work/group-1                       # Windows: ./quality-local.ps1 -Path "C:\work\group-1"
```

It runs all six gates with whichever tools you have, prints `[ OK ]`, `[FIND]` or `[SKIP]` for each, writes
`.quality/local-report.md` (never committed), and exits 1 if a gate that blocks in the pipeline has findings.

**Green looks like:** every format and lint command silent, all tests passing, and `quality-local` ending with
*Nothing that blocks*.

### Optional — make your laptop run it for you (pre-push hook)

From the root of your case repo, once per laptop:

```bash
mkdir -p .githooks && cp <lab>/hooks/pre-push .githooks/ && chmod +x .githooks/pre-push
git config core.hooksPath .githooks
```

Every `git push` now runs format, lint, tests and scenarios for your stack, and gitleaks on the commits you
are pushing — and stops the push if anything is red. Commit `.githooks/` so the whole group has it (each person
runs the `git config` line once). On Windows, Git for Windows runs the hook with its own bash — nothing to install.
Skip it only with a reason the group would accept: `git push --no-verify`.

---

## 3 · The GitLab pipeline

### 3.1 · Is the project ready? (Maintainer, 5 minutes — once)

You did this in Session 11 ([`../09-session11-12-ai-engineering/SETUP-GATE.md`](../09-session11-12-ai-engineering/SETUP-GATE.md)). Check it is still true:

| Where | What you should see |
|---|---|
| *Settings → CI/CD → Runners* (expand) | A runner tagged **`junior-SWAT-engineers-program`** with a **green** dot |
| *Settings → Merge requests → Merge checks* | **Pipelines must succeed** ticked — without it a red gate does **not** stop a merge |
| *Settings → Repository → Protected branches* | `main`: allowed to merge — **Developers + Maintainers**; allowed to push and merge — **No one** |

### 3.2 · Add the pipeline files

Part A of the [README](README.md): `setup-quality` on a fresh `main`. It creates the branch `setup/layer-4` with one
commit: `ci/quality.yml` and `ci/scenarios.yml` added, both included from `.gitlab-ci.yml`, the stages `check` and
`test` made sure of. Then commit your lint configuration (section 1) on the same branch.

Read the result before pushing:

```bash
git -C ~/work/group-1 show --stat HEAD          # what setup-quality changed
cat ~/work/group-1/.gitlab-ci.yml               # stages: [check, test, ...] and the include: list
```

If `.gitlab-ci.yml` still has the Session 10 jobs `lint:` and `secrets:`, delete them now — `qa:lint` and
`qa:secrets` replace them.

### 3.3 · Push, and check the YAML

```bash
git -C ~/work/group-1 push -u origin setup/layer-4 -o merge_request.create -o merge_request.target=main
```

In GitLab: **Build → Pipeline editor**, choose the branch `setup/layer-4`:

- **"Pipeline syntax is correct"** at the top — good. An error names the file and line; fix, commit, push.
- **Visualize** shows the stages and jobs; **Full configuration** shows `.gitlab-ci.yml` with every include
  merged in — the exact pipeline that runs.

### 3.4 · Read the pipeline

Open the merge request → **Pipelines** tab → the pipeline → you see the stages as columns:

```
check                         test
qa:lint                       test            (your Session 10 job)
qa:complexity                 scenarios
qa:secrets                    qa:sast
                              qa:dependencies
                              qa:iac          (only if infra/*.tf exists)
```

- Click a job for its **log**. The last lines say why it failed. **Retry** (top right) re-runs one job — for a
  network hiccup only, never to make a real finding go away.
- **Job artifacts** (right-hand panel) → *Browse* or *Download*: `gl-code-quality.json`, `gl-sast-report.json`,
  `scenarios.xml`.
- In the merge request's **Overview**: lint findings appear under *Code Quality*; test and scenario results
  under the test summary (each scenario by name).

**Expect red on the first run.** For every red job: read the log, run the same check locally (table in 3.5),
then `/triage-findings <gate>` — README step 3.

### 3.5 · Each job and its local twin

| Job | Runs | Same thing on your laptop |
|---|---|---|
| `qa:lint` | ruff / Prettier + ESLint / Spotless + Checkstyle, in `QA_APP_DIR` | section 2, first two columns |
| `qa:complexity` | `lizard -C $QA_COMPLEXITY_LIMIT -w` on `QA_APP_DIR`, tests excluded | `lizard -C 10 -w <app folder>` |
| `qa:secrets` | `gitleaks git` on the **whole history** | `gitleaks git --redact -v .` |
| `qa:sast` | `semgrep scan --config p/default`; ERROR blocks | `semgrep scan --config p/default --exclude specs --exclude .claude .` |
| `qa:dependencies` | `osv-scanner scan source -r` on `QA_APP_DIR` | `osv-scanner scan source -r <app folder>` |
| `qa:iac` | `checkov -d infra` | `checkov -d infra --compact` |
| `scenarios` | the scenarios alone, junit report | section 2, last column |

### 3.6 · Set the baselines, then merge

After `/quality-gates` wrote `specs/design/quality-gates.md`, set the matching values at the top of `ci/quality.yml`:

```yaml
variables:
  QA_APP_DIR: "backend"            # your app folder - "." if the build file is at the root
  QA_COMPLEXITY_LIMIT: "10"        # your E-003
  QA_COMPLEXITY_BASELINE: "3"      # functions above the limit today - from quality-gates.md
  QA_IAC_BASELINE: "7"             # failed IaC checks today - from quality-gates.md
```

Commit, push — the pipeline runs again on the same merge request. Green: a groupmate approves, **Merge**. Then
**Build → Pipelines** shows the pipeline on `main`; from now on every branch and every merge request runs it.

---

## 4 · When the pipeline will not start, or is red for a setup reason

| You see | It means | Do this |
|---|---|---|
| No pipeline at all after the push | `.gitlab-ci.yml` is not on the branch, or CI/CD is off for the project | `git show --stat HEAD`; *Settings → General → Visibility → CI/CD* on |
| Pipeline: **yaml invalid** | A syntax error, or an `include:` path that does not exist | *Build → Pipeline editor* names the line. Paths are `ci/quality.yml`, relative to the repo root |
| Jobs **pending** / *stuck* | No runner with the tag `junior-SWAT-engineers-program` for this project | Section 3.1, first row — show it to your facilitator |
| *stage check does not exist* | `stages:` lacks `check` | `stages: [check, test, deploy]` in `.gitlab-ci.yml` |
| Two pipelines per push | An old job without rules runs on merge-request events | Give it the same `rules:` as `.qa` in `ci/quality.yml` |
| `qa:lint`: `npm ci` … *package-lock.json* | The lockfile is not committed | `npm install`, commit `package-lock.json` |
| `qa:lint`: *No plugin found for prefix 'spotless'* | The plugins are not in this `pom.xml`, or `QA_APP_DIR` points at the wrong folder | Section 1, Java; set `QA_APP_DIR` |
| `qa:lint`: *couldn't find an eslint.config* | The config is not in `QA_APP_DIR` | Copy it next to `package.json` |
| `qa:lint` red on files you never wrote (generated, vendored) | They are inside the lint path | Exclude them: `extend-exclude` in `ruff.toml`, `ignores` in `eslint.config.mjs`, `.prettierignore` — with a comment why |
| Local green, pipeline red on lint | A different tool version | Pin the version the pipeline uses (section 0 and 1) |
| `qa:dependencies`: *No lockfile or pinned requirements* | Nothing to check | Commit `package-lock.json`, pin `requirements.txt`, or let Maven resolve `pom.xml` |
| `qa:secrets` red on a commit you already fixed | gitleaks reads the whole history | A false positive: `.gitleaksignore` with its fingerprint. A real secret: revoke it **first**, then tell your facilitator |
| `qa:sast`: cannot download rules | The runner cannot reach semgrep.dev | README, *If something goes wrong* |
| `scenarios`: *0 scenarios* / no `tests/step_defs` | The runner does not find your features or steps | Your stack's README in `stacks/` — the features path |

Still stuck after ten minutes? Push what you have, write the problem in the merge request, and ask your facilitator.
A red pipeline you can explain is progress; a gate switched off to make it green is not.
