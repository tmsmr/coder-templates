# ADR-004: No SSH Public Key Support in `cloud-config`

## Context

Suggestion: Add a `coder_parameter` for SSH public key and inject it into the `cloud-config` user definition.

## Decision

We will **not** add SSH public key configuration to the template.

## Rationale

- Workspace access is exclusively through the Coder agent (web terminal, JetBrains Gateway, VS Code, etc.). SSH is not a supported access method for end users.
- Adding an SSH key parameter would imply SSH is a feature, which would confuse users and lead to support requests about why SSH doesn't work (because the firewall blocks it by design; see ADR-002).
- During template development or emergency debugging, the operator can manually inject SSH keys into `cloud-config` and temporarily open firewall rules. This is a local development concern, not a template feature.

## Consequences

- Users cannot use SSH for workspace access. They must use Coder-provided clients.
- Emergency debugging requires manual local changes, which is acceptable given the rarity of the need.
