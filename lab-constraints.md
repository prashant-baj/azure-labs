# Azure Lab Constraints (vlabs subscription)

The vlabs lab subscription enforces a **deny policy** — `Az_FullStackFoundational`
(policy set `Az_FullStackFoundational_AllowFullStackAzureResources`, effect: **deny**).
It restricts **where** you can deploy, **which VM sizes** you can use, and **which
resource types** are allowed. Anything not on the allow-list is blocked at deployment
time with `RequestDisallowedByPolicy`.

> Participants cannot exempt themselves from this policy. All labs must stay inside these
> limits. To change the policy, request it from vlabs (they own the subscription).
>
> Derived from the live policy on 2026-09-22. Re-verify anytime with:
> `az policy definition show --name Az_FullStackFoundational_AllowFullStackAzureResources --query policyRule -o json`

## 1. Allowed regions

Deploy resources **only** in:

| Region | Name |
|--------|------|
| `eastus` | East US **(recommended default for all labs)** |
| `eastus2` | East US 2 |
| `canadacentral` | Canada Central |
| `global` | (for global-scoped resources only, e.g. Front Door, DNS) |

`centralindia` and all other regions are **denied**. Note: **resource groups** can be
created in any region (RG location is metadata and isn't policed), so an RG in
`centralindia` may succeed — but nothing can be deployed *into* it there. Always create
lab resource groups in `eastus` to avoid confusion.

## 2. Allowed VM sizes

Virtual machines are allowed **only** in these sizes:

| Size | vCPU / RAM |
|------|-----------|
| `Standard_B1ms` | 1 vCPU / 2 GiB |
| `Standard_B2ms` | 2 vCPU / 8 GiB |

Any other size (including `Standard_B1s`, `D`/`E`/`F` families, etc.) is **denied**.

## 3. Allowed resource types

The policy permits this "full-stack" set. Anything **not** listed here is denied.

**Compute**
- Virtual Machines *(size-restricted, see above)*, Disks, Availability Sets, VM Scale Sets

**Containers**
- Container Apps + Managed Environments + Jobs (`Microsoft.App/*`)
- Container Instances (ACI)
- Azure Kubernetes Service (AKS — `managedClusters`)
- Container Registry (ACR)

**Web / Serverless**
- App Service (`Microsoft.Web/sites`) and App Service Plans (`serverFarms`)
  — this covers **Azure Functions** and **Web Apps**
- Static Web Apps, API connections (`Microsoft.Web/connections`)

**Data & storage**
- Storage Accounts
- Key Vault
- Azure Database for MySQL (Flexible Server)
- Cosmos DB (`DocumentDB/databaseAccounts`)
- Azure Cache for Redis

**Integration & messaging**
- API Management
- Event Grid (topics, subscriptions, domains, system topics)
- Event Hubs, Service Bus
- Logic Apps (workflows, integration accounts, ISE)

**Networking**
- Virtual Networks, Subnets, NSGs, NICs, Public IPs (+ prefixes)
- Load Balancers, NAT Gateways, Route Tables, Network Watcher
- Private Endpoints, Private DNS Zones, Bastion
- Application Gateway (+ WAF policy), Front Door (+ WAF policy)
- Public DNS Zones, CDN profiles

**Identity**
- User-Assigned Managed Identities

**Monitoring & management**
- Application Insights, Log Analytics Workspaces
- Action Groups, Metric Alerts, Activity Log Alerts, Scheduled Query Rules
- Diagnostic Settings, Data Collection Rules / Endpoints, Workbooks
- Azure Managed Grafana, Azure Monitor accounts
- Cost Management (budgets, exports, views), Advisor

**Core**
- Resource Groups, Deployments (ARM/Bicep)

## 4. Notable services that are NOT allowed

Because they're absent from the allow-list, these are **denied** (non-exhaustive):
Azure SQL Database / SQL Managed Instance, PostgreSQL, Synapse, Data Factory,
Databricks, Machine Learning, Azure OpenAI / Cognitive Services, Service Fabric,
HDInsight, Batch, Spring Apps, SignalR, Stream Analytics.

> If a lab needs one of these, either redesign around an allowed equivalent
> (e.g. **MySQL Flexible** or **Cosmos DB** instead of Azure SQL) or ask vlabs to widen
> the policy.

## 5. Practical defaults for lab authors

- Set **`location = eastus`** in every lab and every script default.
- If a lab spins up a VM, use **`Standard_B1ms`** (or `B2ms` if it needs more RAM).
- Prefer the container/serverless services on the allow-list (Container Apps, ACI, AKS,
  App Service/Functions) — they're all permitted and cheaper to run than VMs.
- Expect the `az` CLI to print a long Python traceback ending in
  `The content for this response was already consumed` when a deployment is policy-denied.
  That trailing traceback is a cosmetic az CLI bug — the real reason is the
  `RequestDisallowedByPolicy` block above it.
