# coder-templates

Coder workspace templates (IaC). Currently ships one template: `hcloud/` (Hetzner Cloud server with persistent home volume, JetBrains Gateway, and OpenCode).

## Working in this repo

- There are no tests, `Makefile`, or CI pipelines. Validation is Terraform-native.
- Before committing changes inside `hcloud/`, run:
  ```bash
  terraform fmt -check -recursive
  terraform validate
  ```
  If formatting fails, run `terraform fmt -recursive`.

## Secrets

- `hcloud_token` is required for all Terraform operations.
- It is passed as a Terraform variable. The conventional local file is `hcloud/secrets.auto.tfvars` (gitignored) containing:
  ```hcl
  hcloud_token = "<token>"
  ```
- Do not commit secrets. `secrets.auto.tfvars` is already ignored in `hcloud/.gitignore`.

## Architecture & non-obvious details

- **Dynamic API lookups**: `data.tf` fetches live Hetzner Cloud data at plan time (locations, server types, images). This means `terraform plan`/`apply` requires a valid `hcloud_token` **and** internet access.
- **OS image value format**: The `hcloud_server_os` parameter stores values as `"ubuntu-24.04;x86"` (semicolon-separated). `main.tf` splits on `;` to get the image name and architecture. Keep this format when modifying `parameters.tf` or defaults.
- **Agent architecture mapping**: `data.tf` maps Hetzner architecture names (`x86` → `amd64`, `arm` → `arm64`) with a fallback to `amd64`. The `coder_agent` resource uses this mapped value.
- **cloud-config is the bootstrap contract**: `cloud-config.yaml.tftpl` handles all first-boot setup: persistent volume mount at `/home/coder`, Coder agent systemd service, and the `projects/` directory. Changes to volume mounting or agent startup paths must stay consistent with `main.tf`.
- **Pinned module versions**: `apps.tf` pins JetBrains (`1.4.0`) and OpenCode (`0.1.2`) module versions. Upgrading these may require matching Coder provider version changes; verify in `.terraform.lock.hcl`.
- **Firewall is default-deny + ICMP**: `firewall.tf` creates a firewall with only ICMP ingress allowed. All other inbound traffic is dropped by default.

## Architecture Decision Records (ADRs)

- The `adr/` directory contains decision records for suggestions that were reviewed and intentionally not implemented.
- **Before proposing a new change that touches volume lifecycle, firewall rules, SSH access, volume formatting, or snapshots**, check the existing ADRs to see if the topic has already been discussed:
  ```bash
  ls adr/
  ```
- Current ADRs:
  - `001-no-prevent-destroy-on-volume.md`
  - `002-default-deny-firewall.md`
  - `003-no-manual-volume-formatting.md`
  - `004-no-ssh-keys-in-template.md`
  - `005-no-automated-snapshots.md`
- If an ADR exists, respect the decision or open a new discussion rather than silently re-introducing the same suggestion.

