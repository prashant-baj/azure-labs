# 09c · Workshop project — continuous deployment of a test resource to Azure

**When:** 23 Oct, mid-point check-in · **Time:** about 80 minutes · **Who:** the group's Maintainers drive; everyone reviews

In 09b you proved the path on a throw-away test project. Today the same path goes into **your workshop
project** — the repository you have been building since Session 5:

```
 merge request ──► main ──► your lint + test jobs ──► cdtest:state ──► cdtest:plan ──► cdtest:apply ──► cdtest:verify
                                   (must pass)              │                                              │
                                                  GitLab ID token (OIDC)                     the page shows THIS commit
                                                  → Azure, no secret stored
```

What gets deployed is deliberately tiny and test-only: **one resource group and one storage account
serving one web page** that names the commit and pipeline that deployed it. No compute, nothing billed
by the hour, ready in about a minute. It is destroyed at the end — by you, or automatically after two
hours. Your own `infra/` comes later; first the *path* has to be boring.

By the end you will have:

1. The pipeline in your workshop repo, merged through your own gate
2. One deployment from `main`, signed in to Azure **with OIDC**, verified by the pipeline itself
3. A second deployment, triggered only by merging a change
4. The test resource destroyed, and the run recorded in `infra-test/DEPLOYED.md`

| Step | What | Who | Time |
|---|---|---|---|
| 1 | Trust the workshop project (OIDC) | Facilitator, before the lab | — |
| 2 | Add the pipeline and Terraform | One Maintainer | 10 min |
| 3 | Merge request through your gate | Whole group | 15 min |
| 4 | Watch `main` deploy — checkpoint 1 | Whole group | 15 min |
| 5 | Roll out a change by merging — checkpoint 2 | Whole group | 20 min |
| 6 | Destroy, record, debrief — checkpoint 3 | Whole group | 20 min |

---

## Step 1 — Trust the workshop project *(facilitator, before the lab)*

The Azure side trusts **one project and one branch** per federated credential. Your group's app registration
trusts the *test project* today. It needs one more credential for the workshop project. Participants cannot
do this — it changes an app registration and a role in your subscription.

> **Participants:** check it is done — workshop project → **Settings → CI/CD → Variables** shows
> `AZURE_OIDC_CLIENT_ID`, or your **group's** CI/CD variables do. If neither does, tell your facilitator and
> start step 2 anyway — the deploy will wait.

### Option A — reuse the group's existing app (Azure Portal, ~3 min per group)

1. **Microsoft Entra ID → App registrations → All applications.** Open the app you made for the group's test
   project. Its *Application (client) ID* is the `AZURE_OIDC_CLIENT_ID` value in the test project's variables.
2. **Certificates & secrets → Federated credentials → + Add credential.**
3. Fill in:

   | Field | Value |
   |---|---|
   | Federated credential scenario | **Other issuer** |
   | Issuer | `https://gitlab.stackroute.in` |
   | Type | **Explicit subject identifier** |
   | Value | the subject for the group, from the table below |
   | Name | `gitlab-workshop-main` |
   | Audience | `api://AzureADTokenExchange` *(the default)* |

4. **Add.** No new role is needed: Contributor on the subscription belongs to the app, not to a project.
5. **GitLab →** workshop project **→ Settings → CI/CD → Variables** — skip this if the three variables are
   already on the **group** (*Group → Settings → CI/CD → Variables*), which the project inherits:

   | Key | Value | Visibility | Protect | Expand |
   |---|---|---|---|---|
   | `AZURE_OIDC_CLIENT_ID` | the app's Application (client) ID | Visible | **On** | Off |
   | `AZURE_TENANT_ID` | `eaTenantId` from the vlabs panel | Visible | **On** | Off |
   | `AZURE_SUBSCRIPTION_ID` | `eaSubscriptionGuid` from the vlabs panel | Visible | **On** | Off |

   All three are IDs, not secrets. *Protect* means only protected branches — `main` — receive them.
6. **Settings → Repository → Protected branches:** `main` is protected (it is by default; check nobody changed it).

| Group | Subject (Value field) |
|---|---|
| 1 | `project_path:mindsprint-group1/case-a-nova-retail:ref_type:branch:ref:main` |
| 2 | `project_path:mindsprint-group2/case-b-sterling-bank:ref_type:branch:ref:main` |
| 3 | `project_path:mindsprint-group3/case-c-purefoods:ref_type:branch:ref:main` |
| 4 | `project_path:mindsprint-group4/case-d-apex-industrial:ref_type:branch:ref:main` |
| 5 | `project_path:mindsprint-group5/case-e-econova:ref_type:branch:ref:main` |

The subject must match **exactly** — group, project path as in the URL, branch `main`. One wrong character and
Azure answers `AADSTS700213: No matching federated identity record`.

Check from a terminal, signed in as Owner:

```bash
az ad app federated-credential list --id <AZURE_OIDC_CLIENT_ID> --query "[].subject" -o tsv
az role assignment list --assignee <AZURE_OIDC_CLIENT_ID> --all --query "[].{role:roleDefinitionName, scope:scope}" -o table
```

### Option B — the script

`gitlab-setup/setup-oidc-all.ps1` does the same for all five groups, but with a **separate app per workshop
project** (`gitlab-mindsprint-groupN-<project>`): app, credential, Contributor, and the three project variables.
Fill the `subscription` column of `oidc-groups.csv`, then `setup-oidc-all.cmd -DryRun`, then without
`-DryRun`. Project-level variables override group-level ones, so the workshop project uses its own app and the
test project keeps its own.

---

## Step 2 — Add the pipeline and the Terraform *(one Maintainer, 10 min)*

From this lab folder, pointing at your local clone of the workshop repo:

```powershell
# Windows
.\setup-workshop-cd.ps1 -Path "C:\work\case-a-nova-retail"
```
```bash
# macOS / Linux / WSL
./setup-workshop-cd.sh ~/work/case-a-nova-retail
```

It never overwrites your files. It:

| Adds / changes | Why |
|---|---|
| `ci/cd-test.yml` | The pipeline jobs, all named `cdtest:*` so they sit next to anything you already have |
| `infra-test/*.tf`, `infra-test/site/` | The test resource: resource group `rg-wk<N>-cdtest`, storage account `stwk<N>…`, one page |
| `infra-test/DEPLOYED.md` | Your record — filled in during steps 5 and 6 |
| `.gitlab-ci.yml` | Includes `ci/cd-test.yml`; adds the stages `test` and `deploy` if your `stages:` list lacks them (the Session 10 starters have `[check, test]`) |
| `.gitignore` | `.terraform/`, `*.tfstate`, `*.tfplan`, `*.tfvars` — state can hold secrets and never goes to git |
| a commit on branch `cd-test` | `main` is protected — this goes in by merge request like everything else |

The names use `wk<N>` (your group number), so they never clash with the `cd<N>` resources of your 09b test
project. The Terraform state lives in an Azure storage account the pipeline creates, keyed by project — not on
anyone's laptop.

Before pushing, **read the diff together** (`git show --stat`, then the files). You are about to give a pipeline
the right to change your Azure subscription; know what it does.

---

## Step 3 — Merge request through your gate *(whole group, 15 min)*

```bash
git push -u origin cd-test -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="CD test: deploy a test resource to Azure"
```

On the branch pipeline you will see **`cdtest:validate`** (Terraform `fmt` + `validate`, no Azure needed), next to
your lint and test jobs — and the AI review, if your gate has it. Nothing deploys from a branch: the Azure
variables are protected, so a branch could not sign in even if it tried.

**In the merge request,** before approving, the reviewers answer these in a comment:

1. Which jobs run on a branch, which only on `main`? What makes the `cdtest:*` deploy jobs wait for your tests?
2. What exactly can this pipeline do in Azure — and with which identity? Where would you see that identity in Azure?
3. Where does the Terraform state live, and what happens to it when vlabs cleans the subscription?
4. Which files, when changed, cause a deployment — and which do not?

*(Answers are in the comments at the top of `ci/cd-test.yml`.)* Resolve every thread, approve, **merge**.

---

## Step 4 — Watch `main` deploy *(15 min)* · **Checkpoint 1**

**Build → Pipelines →** the pipeline for the merge commit on `main`. After your lint and test jobs pass:

| Job | Look for in the log |
|---|---|
| `cdtest:state` | `Azure sign-in: OIDC - short-lived GitLab token, no secret stored` — then `Signed in as <app id> to <subscription>` |
| `cdtest:plan` | `Plan: 4 to add, 0 to change, 0 to destroy` — resource group, storage account, static website, page |
| `cdtest:apply` | `Apply complete!` and `SITE_URL=https://st….web.core.windows.net/` |
| `cdtest:verify` | `… shows commit <sha> - deployed by this pipeline` |

Then **Operate → Environments → `cd-test` → Open.** The page shows your project, commit and pipeline.

✅ **Checkpoint 1:** the page is up and shows the merge commit's short SHA. Show your facilitator.

If the log says `Azure sign-in: team service principal secret (fallback …)`, it still worked — but not with
OIDC. Step 1 is not finished for your project; tell your facilitator.

---

## Step 5 — Roll out a change by merging *(20 min)* · **Checkpoint 2**

Continuous deployment means *the merge is the deploy*. Prove it:

1. New branch from `main`, e.g. `cd-test-change`.
2. In `infra-test/variables.tf`, change the default of `message` to a sentence of your own.
3. In `infra-test/DEPLOYED.md`, fill in the first four rows from step 4 (pipeline link, site URL, commit, sign-in line).
4. Push, merge request, `cdtest:validate` green, review, merge.
5. On `main`: `cdtest:plan` now shows a **change**, not 4 new resources — read it: what is replaced, what is updated in place, and why?
6. `cdtest:verify` passes with the **new** commit; the page shows your sentence.

✅ **Checkpoint 2:** the page changed because of a merge, and no one ran `az` or `terraform` by hand.

> **Try it, then undo it:** add a *third* branch that changes only `infra-test/DEPLOYED.md` or a spec. Its
> merge runs your tests but **does not deploy** — the deploy jobs only run when `infra-test/*.tf`,
> `infra-test/site/*` or `ci/cd-test.yml` change, or when someone presses **Build → Pipelines → Run pipeline**
> on `main`. Why is that the right behaviour for infrastructure?

---

## Step 6 — Destroy, record, debrief *(20 min)* · **Checkpoint 3**

1. **Operate → Environments → `cd-test` → Stop.** That runs `cdtest:destroy` (`Destroy complete! Resources: 4 destroyed.`).
   *(If you forget, GitLab stops it two hours after the last deploy — `auto_stop_in` in `ci/cd-test.yml`.)*
2. Check in Azure: `rg-wk<N>-cdtest` is gone (Portal, or `az group show -n rg-wk<N>-cdtest` → *not found*).
   `rg-tfstate` stays — it holds the state, and costs cents.
3. Finish `infra-test/DEPLOYED.md`: the second pipeline, *Destroyed: yes, <date>*, and two or three lines of
   *What we learned*. Merge it — and notice it does **not** redeploy.
4. Run the check:

```powershell
.\check-workshop-cd.ps1 -Path "C:\work\case-a-nova-retail"
```
```bash
./check-workshop-cd.sh ~/work/case-a-nova-retail
```

✅ **Checkpoint 3:** `READY - the path works.`

**Debrief (mid-point check-in):**

- The pipeline's identity has **Contributor on the whole subscription**. What would you narrow, and how
  (scope, role, a second credential for another branch)?
- What did the pipeline catch that a person deploying from a laptop would not have?
- To deploy your real component next: what changes — only `CDTEST_ROOT` and the Terraform, or more? What must
  be true about your tests before `main` is allowed to deploy it?

---

## Troubleshooting

| Symptom (job log) | Cause | Fix |
|---|---|---|
| `No Azure identity on this pipeline` | `AZURE_OIDC_CLIENT_ID` not on the project or group — or the pipeline ran on an unprotected branch | Step 1.5 and 1.6. Deploy jobs only run on `main` |
| `AADSTS700213: No matching federated identity record found for presented assertion subject 'project_path:…'` | No credential with that exact subject | Copy the subject from the error into the Portal (step 1.3) — it shows what GitLab really sent |
| `AADSTS700211` / `AADSTS50166` (issuer) | Issuer typed differently | Exactly `https://gitlab.stackroute.in` — no trailing slash |
| `AuthorizationFailed … does not have authorization to perform action` | The app has no Contributor role — or vlabs reset the subscription | Facilitator: `az role assignment create --assignee <client id> --role Contributor --scope /subscriptions/<sub>` |
| `MissingSubscriptionRegistration … Microsoft.Storage` | Provider not registered in this subscription | Facilitator: `az provider register -n Microsoft.Storage` (needs Owner) |
| `RequestDisallowedByPolicy` | Lab policy: region or SKU | Keep `location = "eastus"` (or `eastus2`, `canadacentral`), `Standard_LRS` |
| `chosen stage deploy does not exist` | `stages:` lacks `deploy` | Add it: `stages: [check, test, deploy]` |
| `cdtest:validate` fails at `terraform fmt -check` | Formatting | `terraform fmt -recursive` in `infra-test/`, commit |
| Jobs stuck *pending* | Runner tag | Jobs use `junior-SWAT-engineers-program` — check with your facilitator |
| `Error acquiring the state lock` | A cancelled run left a lock | Wait a minute and retry; jobs never overlap (`resource_group`). Still locked → facilitator |
| `cdtest:verify` keeps retrying | Page not served yet, or an old page | Open `SITE_URL` from the `cdtest:apply` log; retry the job |
| Deploy jobs missing from the `main` pipeline | Nothing under `infra-test/*.tf`, `infra-test/site/*` or `ci/cd-test.yml` changed | Working as designed — **Build → Pipelines → Run pipeline** on `main` to deploy anyway |
| Everything was fine, now `ResourceGroupNotFound` / state errors | vlabs cleans the subscription about every 4 hours | Run the pipeline again: `cdtest:state` recreates the state account; Terraform recreates what is missing |

---

## For the facilitator

- **Before the lab:** step 1 for each group (Option A or B). If participants arrive first, they can do steps 2–3
  meanwhile; `main`'s deploy jobs fail with *No Azure identity* until the variables exist — then **Run pipeline**.
- **Progress:** the review utility includes this lab as **Mid** (23 Oct) — it runs `check-workshop-cd` on each
  group's `main` and branches. `infra-test/DEPLOYED.md` is the evidence; the pipeline links in it are the proof.
- **Cost and clean-up:** a Standard_LRS storage account with one page costs effectively nothing; `auto_stop_in: 2 hours`
  destroys it even if a group forgets. The state accounts in `rg-tfstate` remain until the vlabs cleanup.
- **Nothing secret is created** in this lab. The only secret in play is the fallback `AZURE_CLIENT_SECRET`
  already on the group — the log line in `cdtest:state` tells you which identity each group used.
