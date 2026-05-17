# ADR-001: No `prevent_destroy` on `hcloud_volume`

## Context

Suggestion: Add `lifecycle { prevent_destroy = true }` to the persistent home volume to prevent accidental data loss when the server location parameter changes.

## Decision

We will **not** add `prevent_destroy` to `hcloud_volume`.

## Rationale

- The `hcloud_location` parameter is immutable (`mutable = false`) in the Coder workspace configuration. Once a workspace is created, the location cannot be changed through the Coder UI.
- If location needs to change, it requires creating a new workspace, which would inherently need a new volume in the new location.
- Adding `prevent_destroy` would block legitimate Terraform operations (e.g., workspace deletion) and require manual `terraform state rm` intervention, which is error-prone for operators.
- The volume is already protected by the fact that the only attribute bound to a mutable parameter is `size`, which does not trigger recreation.

## Consequences

- Operators must understand that `hcloud_location` is a create-time decision, not a runtime mutable setting.
- If someone manually edits state files or Terraform code to change location, the volume will be destroyed. This is acceptable because such changes are outside supported workflows.
