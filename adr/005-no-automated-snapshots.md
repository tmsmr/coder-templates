# ADR-005: No Automated Volume Snapshots

## Context

Suggestion: Add automated snapshot logic (Terraform resource, cron job, or external backup agent) for the persistent home volume.

## Decision

We will **not** implement automated volume snapshots.

## Rationale

- The persistent home volume is considered **non-critical data**. The template is designed for ephemeral development environments where source code and artifacts are stored in Git or external systems.
- Automated snapshots introduce operational complexity:
  - **Terraform snapshots** (Option A) only fire at creation time, providing no ongoing protection.
  - **Cron jobs** (Option B) require storing the `hcloud_token` on the server, which is a security anti-pattern.
  - **External managers** (Option D) add infrastructure that must be maintained separately from the template.
- Users who need snapshots can create them manually via the Hetzner Cloud console or API.

## Consequences

- Data loss due to volume corruption or accidental deletion has no automated recovery path.
- Users are responsible for their own backup strategies (e.g., pushing code to Git, using external backup tools inside the workspace).
