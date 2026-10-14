---
description: Find the gaps between your specs and what must actually be deployed in Azure — then ask the group pointed questions. No Terraform yet.
argument-hint: "[slice folder, e.g. specs/001-first-slice]"
---
Slice folder: $ARGUMENTS (if empty, use the only `specs/NNN-*` folder).

You are helping a group of engineers prepare their case for deployment on Azure. You **find gaps
and ask**; the group **decides**. You do not write Terraform in this command.

## Read first (all of it, before you say anything)

`constitution.md` (glossary, C- rules, Q floors, W- and E- rules) · `specs/design/` (every ADR —
especially the architecture-and-stack ADR — the NFR register, constraints, contracts) ·
`<slice>/spec.md` · `<slice>/plan.md` (§8 stack, §11 diagrams, §12 components) ·
`specs/design/azure-lab-constraints.md` (the lab policy) · `docs/` (the evidence) · any existing `infra/`.

## Step 1 — the resource map (show it, do not save it yet)

From the plan's components and the ADR, list every Azure resource this slice needs to run, one row
each, and check each against the lab constraints:

| Need (from which line) | Azure resource | Lab policy | Decided in | Gap |
|---|---|---|---|---|

Cover all of these, even if the answer is "not needed — because …":
compute/hosting · data store · messaging/events · secrets · identity between services · container
registry · networking/ingress · observability (logs, metrics) · the deploy identity (who runs
Terraform / the pipeline) · environments · cost.

Lab facts you must respect (also in `specs/design/azure-lab-constraints.md`):
- Regions: `eastus` (default), `eastus2`, `canadacentral` only.
- **Proven to deploy:** Container Apps + Container Registry (admin credentials), Cosmos DB
  (serverless), Service Bus (Standard), Key Vault, Log Analytics + Application Insights, Storage.
- **Allowed but no compute quota:** App Service and Functions — do not plan on them.
- **Denied:** Azure SQL, PostgreSQL, Azure OpenAI / Cognitive Services, Databricks, Data Factory,
  Synapse, Machine Learning (and anything else not on the allow-list).
- VMs only `Standard_B1ms` / `Standard_B2ms` — and only if nothing serverless fits.
- The lab role cannot create **role assignments** → Key Vault access policies, ACR admin credentials.
- The lab is cleaned roughly every four hours → everything must be re-creatable from code.

## Step 2 — classify every gap

Use exactly these kinds, and quote the spec line each one comes from:
- **Undecided** — the spec needs it, no ADR or plan line decides it.
- **Policy conflict** — the ADR or plan names something the lab denies or cannot run (no quota).
- **Requirement with no resource** — an NFR or C- rule (availability, retention, data location,
  audit, latency) that no planned resource can meet.
- **Resource with no requirement** — something planned that no requirement asks for.
- **Security** — secrets, identity, public exposure, data leaving the system.
- **Operability** — logs, health check, how a failure is noticed, how it is rolled back.
- **Cost** — anything always-on, or with no budget owner.

## Step 3 — ask the group, one question at a time

Ask **pointed** questions — at most eight, the riskiest first. Each question:
- quotes the spec or ADR line it comes from;
- offers two or three concrete options, each with its consequence on Azure;
- ends with "Which one, and who in the client's team would agree?"

Wait for each answer before the next question. If the group does not know, write
`[NEEDS CLARIFICATION: <question> — ask <stakeholder>]` and move on. **Never answer for them.**

## Step 4 — write it down

Save `specs/design/azure-gaps.md` with: the resource map, every gap with its kind and source, the
question asked, the group's answer (or NEEDS CLARIFICATION), and the follow-up — which ADR or plan
section must change. Propose (do not apply) the ADR changes as a short list.

End with: "Resolved X of Y gaps. The open ones block `/azure-terraform` for: …".
Do not create or change any other file.
