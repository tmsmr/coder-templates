---
name: hcloud-instance
description: General purpose remote development on a Hetzner Cloud instance
tags: [hcloud]
---

# hcloud-instance

## Authentication
You have to provide a Hetzner Cloud API token (R/W) when the Template is created. The Workspace resources will be created in the project the API token belongs to...

## Persistence
Each Workspace will contain a persistent Hetzner Cloud Volume, which will be mounted as the users `$HOME` folder on Workspace activation.

## TODO
- [ ] Figure out why the metadata labels are not working properly...
