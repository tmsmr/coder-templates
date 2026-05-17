# ADR-002: Default-Deny Firewall (ICMP Only)

## Context

Suggestion: Allow SSH ingress (TCP 22) for operational debugging when the Coder agent fails to start.

## Decision

We will keep the firewall as **default-deny with only ICMP ingress allowed**. We will **not** add SSH rules by default.

## Rationale

- The primary security model is **zero-trust inbound**: the Coder agent connects outbound to the Coder control plane. No inbound ports need to be open for normal operation.
- If template debugging is needed, the operator can temporarily add SSH rules locally in `firewall.tf`, apply, debug, then revert. This is a deliberate opt-in for exceptional circumstances.
- Allowing SSH by default would increase the attack surface for all workspaces without providing value to end users, who access the workspace through Coder's web IDE or Gateway, not SSH.

## Consequences

- When investigating agent startup failures, the operator must temporarily open SSH (or use the Hetzner VNC console) rather than having it pre-available.
- This is acceptable because agent startup failures are rare and the Hetzner console is available as a last-resort debugging path.
