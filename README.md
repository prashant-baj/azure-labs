# azure-labs

Hands-on labs for the MindSprint Junior SWAT Engineering Program 2026, run on the vlabs Azure
lab subscription.

| Folder | What it does |
|--------|--------------|
| [`00-access-check`](00-access-check/README.md) | Confirms you can sign in to the Azure lab account and create resources |
| [`01-prereqs-check`](01-prereqs-check/README.md) | Confirms your local tools are installed |
| [`02-azure-resources-test`](02-azure-resources-test/README.md) | Deploys the lab stack once, to prove it works |
| [`tools`](tools/README.md) | Makes the Azure CLI, Git and npm work behind a company proxy — without switching security off |

Session labs are added to this repository as each session runs. What the lab subscription
allows and blocks is in [`lab-constraints.md`](lab-constraints.md).

**On Windows**, start each lab with its `.cmd` file (double-click it). That works even where
your company blocks PowerShell scripts.
