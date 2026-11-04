# Session 16 workshop: secure, with every threat proved

**By the end of today your group has:**

1. **A threat model of your own slice.** It names what you protect, what could go wrong (STRIDE, letter by
   letter), and for each threat the control that answers it and the test that proves it.
2. **The controls in the code, each written red first.** That means a key that fails closed, security headers,
   and escaped output. The tests are named after the threats they prove.
3. **A secret that never touches a file.** It goes from a masked GitLab variable to Terraform to a Container App
   secret, and the app reads it as an environment variable.
4. **A scan of the running service after every deploy** (`verify:dast`), with two new rows on the scorecard.

Session 17 makes the same service observable. The planned `verify:observability` job you see today becomes real.

| # | Step | Who | Time |
|---|---|---|---|
| 1 | Set up | driver + Maintainer | 10 min |
| 2 | Attack your own service, then model the threats | whole group | 25 min |
| 3 | Controls, red test first | two pairs | 25 min |
| 4 | The secret's journey | driver + Maintainer | 15 min |
| 5 | Merge, deploy, scan, and set the scan's rows | whole group | 20 min |
| 6 | Review and check | driver | 10 min |
| | Debrief | everyone | 10 min |

Commands below are for macOS / Linux / WSL. **PowerShell** lines are given where they differ. `~/work/group-1` is
your case repo, `<lab>` is this folder, and `$APP_URL` is your test environment's address (the `deploy:test` job
prints it, and the GitLab environment *test* links to it).

**Before you start:** your repo has the tag `L5-tested`, `CONFIDENCE_DEPLOY` is `"on"`, and the last pipeline on
`main` deployed and said CONFIDENT. If it did not, fix that first. A scan of a service that is not running proves
nothing.

---

## Step 1 · Set up (10 min)

One person, on a fresh `main`:

```bash
git -C ~/work/group-1 switch main && git -C ~/work/group-1 pull
cd <lab> && chmod +x *.sh
./setup-production.sh ~/work/group-1
```
```powershell
./setup-production.ps1 -Path "C:\work\group-1"
```

This creates the branch `setup/layer-6` with one commit. What matters today:

| File | What it is |
|---|---|
| `specs/design/threat-model.md` | The template. You fill it in during step 2 |
| `specs/design/threat-notes.md` | **Your case's notes**: the checks for step 2, from your case study. Copied from `<lab>/case-notes/` by the repo name |
| `ci/production.yml` | `verify:dast` today. Also the Session 17 jobs: `verify:observability` (planned until then), the drill, rollback |
| `ci/confidence.py` | Updated so the scorecard reads `zap.json` and `obs.json`. If you had changed it, the new one is `confidence.py.new` |
| `infra/secrets.tf` | Every secret the app reads, and where its value comes from. It never holds a value |
| `infra/observability.tf.s17` | Waiting for Session 17. Terraform ignores it until it is renamed |
| `.claude/commands/` | `/threat-model`, `/secure-review`, `/observability-spec`, `/analyse-alert` |

Open Claude Code in your repo once now, so it reads the new `CLAUDE.md` section.

Ran setup before `case-notes/` existed? `git pull` this lab, commit your work, and run `setup-production` again on
the same branch. It adds only what is missing, and leaves everything you already have alone.

**Check:** `./check-production.sh ~/work/group-1` runs and section 1 says the threat model exists, with 0 threats so far.

---

## Step 2 · Attack your own service, then model the threats (25 min)

**First, ten minutes as the attacker.** Before anyone writes a document, try your own deployed service. Pick the
route that returns the most sensitive data in your slice, then:

```bash
curl -si "$APP_URL/<that route>"                                   # no credentials at all
curl -si "$APP_URL/<that route>" -H "X-Role: admin"                # only a header - whatever your app trusts
curl -si "$APP_URL/docs" ; curl -si "$APP_URL/openapi.json"        # does it hand out a map of every route?
curl -sI "$APP_URL/<a page or route>"                              # which security headers come back?
```
```powershell
curl.exe -si "$env:APP_URL/<that route>" -H "X-Role: admin"       # curl.exe, not the PowerShell alias
```

Write down what got through. If a header alone got in, that is your **T-01**, and it is a real finding, not a
hypothetical one. The worked example's T-01 worked exactly like this before layer 6.

**Your case's notes.** Open `specs/design/threat-notes.md`. Its section 5 lists the attacks to try for your case,
and section 2 the STRIDE checks for your slice. Try those too. (If setup could not tell your case from the repo
name, copy yours: `cp <lab>/case-notes/case-<letter>-*.md specs/design/threat-notes.md`. Every group's notes are in
`<lab>/case-notes/`, and the handout has one slide per case.)

**Then, the model:**

```
/threat-model specs/<your slice>
```

It works one section at a time and stops for your yes after each one. It reads `specs/design/`, so your case's
notes go into the model with the rest of your design.

1. **Assets.** What would the client be hurt to lose or leak? Quote the requirement or constraint (C-0nn).
2. **Threats.** Go STRIDE letter by letter. For each letter, ask what an outsider could do, what a real user acting
   out of role could do, and what a careless insider could do. What you just tried goes in first. A letter that
   does not apply to your slice gets one line saying why.
3. **Controls.** Give each threat a `SEC-0nn` from `stacks.md`. No new library without an ADR.
4. **Proof.** Give each control a test named after both IDs (`test_sec_001_t01_...`), plus `verify:dast` for the
   header and disclosure rows.
5. **Accepted for now.** List what you will not fix in this slice, why, and who agreed. "Who agreed" is the
   client's representative, not the group. Until they agree, write `[NEEDS CLARIFICATION]`.

**Check:** `check-production` section 1 shows at least 4 threats, and counts the ticked boxes at the end of your
case's notes. Every threat has a control, and some are still
"no test named after", which is expected until step 3.

---

## Step 3 · Controls, red test first (25 min, two pairs)

Split the controls between the pairs. For each one, the rhythm is the one from Session 13:

1. **Red.** Write the test named after its threat and run it. It must fail against today's code, because that
   failure is the proof the threat was real.
2. **Green.** Add the smallest change from `<lab>/stacks.md` for your stack.
3. **Refactor**, then run the whole suite.

| Pair | Controls | stacks.md |
|---|---|---|
| A | **SEC-001**: the key, checked on every protected route, fail closed (503 when unset), constant-time comparison. Tests: no key gives 401, a wrong key gives 401, no key configured gives 503 | section 1 |
| B | **SEC-002**: security headers on every response, no API explorer in the deployed app. **SEC-003**: escaped output, if you render HTML | sections 2, 3 |

In tests, set the variable to a value used only by tests (`monkeypatch.setenv`, `beforeEach`,
`@SetEnvironmentVariable`). **No real key goes in a test, a fixture or a Postman environment.**

Ask Claude Code for help, and read what it writes: *"Write the failing test for T-01 from
specs/design/threat-model.md, named after it, following stacks.md section 1. Don't change the code yet."*

**Check:** the suite is green, and `check-production` section 2 shows at least 3 security tests, headers set,
constant-time comparison and a key check.

---

## Step 4 · The secret's journey (15 min)

Follow one secret from where it is born to where the app reads it. Nobody on the team needs to see the deployed
value, and no file ever holds it.

```
masked GitLab variable  →  TF_VAR_app_api_key (ci/production.yml)  →  var.app_api_key (infra/secrets.tf, sensitive)
                        →  a Container App secret  →  the environment variable APP_API_KEY inside the container
```

**4a. Make the value, and store it only in GitLab** (Maintainer). Generate a random value:

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(24))"
```

Then in GitLab go to **Settings → CI/CD → Variables → Add variable** and set:

| Field | Value |
|---|---|
| Key | `APP_API_KEY` (or your own name, used the same way everywhere below) |
| Value | the value you just generated |
| Visibility | **Masked** (or *Masked and hidden*) |
| Protect variable | **off**. `api:local` runs on branches and needs it too. This is the *test* environment's key; a production key would be protected |

Close the terminal so the value is not left in your history. If you ever see it in a job log, rotate it.

**4b. Terraform** (driver). `infra/secrets.tf` is already there. Rename `APP_API_KEY` in `local.app_secrets` if
your code reads a different name. Then paste the two blocks from
`<lab>/infra-additions/container-app-secrets.snippet.tf` into `azurerm_container_app` in `infra/main.tf`, as the
snippet's comments say. The first block declares the Container App secret; the second turns it into an
environment variable that refers to the secret, never to the value. Then check:

```bash
cd ~/work/group-1/infra && terraform init -backend=false -input=false >/dev/null && terraform validate
```

**4c. Your own checks send the key.** Your Postman, k6 and Playwright tests now need the key. Follow the table in
`stacks.md`, section 4: add `--env-var apiKey="$APP_API_KEY"` to both `newman` lines and
`-e APP_API_KEY="$APP_API_KEY"` to `k6 run` in `ci/confidence.yml`, and add one Postman request that expects 401
**without** the key.

**Check:** `check-production` section 3 is all OK. That means no secret files in git, sensitive variables,
`main.tf` using `local.app_secret_names`, and Postman environments without values.

---

## Step 5 · Merge, deploy, scan, and set the scan's rows (20 min)

**5a. Add the rows to the strategy** first, in the same merge request. `specs/design/test-strategy.md`, section 5:

```
| CS-0nn | No high-risk finding on the running service | dast.high | = 0 | T-01..T-0n | deploy |
| CS-0nn | Medium-risk findings only go down | dast.medium | [NEEDS CLARIFICATION] | ratchet: the first scan | deploy |
```

In section 6, add `verify:dast` (real) and `verify:observability` (planned, Session 17), the same way you drew the
pipeline in Session 14.

**5b. Push and merge:**

```bash
git -C ~/work/group-1 push -u origin setup/layer-6 -o merge_request.create -o merge_request.target=main
```

The merge request pipeline runs your tests (the security tests included), the quality gates and `api:local` with
the key. `confidence:merge` must say CONFIDENT. Merge it.

**5c. Watch `main`.** The pipeline builds, deploys with the secret, verifies, then runs **`verify:dast`**: ZAP's
baseline scan against your deployed service. It reads only and attacks nothing. In the pipeline view you will
also see the orange `verify:observability (planned)` job. Open the `verify:dast` job's artifacts, then
**`zap.html`**:

- **High** findings: fix them now, with a test first. `dast.high = 0` is not negotiable.
- **Medium** findings: count them. That count is your `dast.medium` ratchet, so replace `[NEEDS CLARIFICATION]`
  with `<= <count>` in a second, small merge request. From now on it only goes down.
- Write what the scan said in section 4 of the threat model. Anything new it found becomes a new `T-0n` row.

**5d. Try T-01 again** against the newly deployed service, with the same `curl` as step 2. It should now get 401.

**Check:** `confidence:deploy` shows the `dast.high` and `dast.medium` rows as met, and `check-production`
section 4 is all OK.

---

## Step 6 · Review and check (10 min)

```
/secure-review main
```

It reviews the slice against your threat model and then the OWASP Top 10. Every finding names a file, a line, a
threat and the test that would catch it, and it edits nothing. Take one finding, write its failing test, and log
the rest in the threat model or as debt.

```bash
cd <lab> && ./check-production.sh ~/work/group-1          # sections 1-4 are today
```

---

## Done looks like

- [ ] `specs/design/threat-model.md`: assets, at least 4 threats across STRIDE, each with a control and a proof, and *accepted for now* with who agreed
- [ ] T-01 tried against your own service before the fix (it got in) and after (401)
- [ ] Every control written red first, with tests named `test_sec_0nn_t0n_...`
- [ ] The secret lives only in a masked GitLab variable. `terraform validate` passes, and no value appears in any file
- [ ] `verify:dast` ran on `main`. `dast.high` = 0, and `dast.medium` is a measured ratchet
- [ ] `check-production` sections 1 to 4: no FAIL

## In Session 17

You will make the same service observable: Application Insights, one business signal and one technical signal,
a dashboard, alerts, and a drill that proves the alerts fire. Before then, as homework:

- Every `[NEEDS CLARIFICATION]` in the threat model answered by the client's representative.
- Each person: name the **one number the client would phone you about**. You will choose one in step 2.
- Find out who should receive the alert emails (a shared inbox is best), so you can set it as `ALERT_EMAIL`.

## If something goes wrong

| Symptom | Fix |
|---|---|
| `verify:dast`: cannot pull `ghcr.io/zaproxy/zaproxy` | The runner cannot reach that registry. Set `ZAP_IMAGE: "zaproxy/zap-stable"` (Docker Hub) in `ci/production.yml` |
| `verify:dast` passes but `zap.json` is missing | The scan never reached the service. Is `APP_URL` set (from `deploy:test`)? Open `zap.html` |
| `confidence:deploy`: `dast.high` NOT MEASURED | `verify:dast` did not run in this pipeline, or `ci/confidence.py` is still the old one (look for `confidence.py.new`) |
| Every protected route returns 503 after deploy | The secret did not arrive: `APP_API_KEY` is not set in GitLab, the `TF_VAR_` line names a different variable, or the snippet's env block is missing. Fail closed is working as designed |
| `api:local` red with 401 on every protected request | The newman line does not pass `--env-var apiKey="$APP_API_KEY"`, or the variable is *protected* and the branch is not |
| The value shows in a job log | Masking needs a value of at least 8 characters with no spaces. Delete the variable, make a new value, and rotate it |
| `terraform validate`: *Reference to undeclared resource* in the snippet | The `dynamic "secret"` block goes at the top level of `azurerm_container_app`; the `dynamic "env"` block goes inside `template { container { … } }` |
| `check-production`: *infra/secrets.tf has a default value* | Only `default = ""` is allowed. A value never goes in a `.tf` file |
| A test passes before the control exists | It does not test the threat. Make it fail on today's code first |
