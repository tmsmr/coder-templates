# ADR-003: No Manual Formatting in `cloud-config`

## Context

Suggestion: Add a `blkid` + `mkfs.ext4` fallback in `cloud-config.yaml.tftpl` `runcmd` to format the volume if `fs_setup` skipped it.

## Decision

We will **not** add manual volume formatting in `runcmd`. We rely on `cloud-init`'s built-in `fs_setup` and `mounts` directives.

## Rationale

- Hetzner Cloud creates volumes pre-formatted as `ext4`. The `fs_setup` directive with `overwrite: false` is a benign no-op safeguard that preserves existing data on rebuilds.
- Adding manual `mkfs.ext4` logic in `runcmd` introduces a risk of accidental data wiping if logic errors occur or if `blkid` parsing fails.
- The current `cloud-init` configuration (wait-for-device + `mount -a`) is sufficient for both new volumes and rebuilds.

## Consequences

- We accept a small risk that `cloud-init` could fail to mount if Hetzner changes their volume initialization behavior. This has not been observed in production.
- If such an event occurs, the fix is to adjust `cloud-config` or report an upstream issue rather than pre-emptively adding complexity.
