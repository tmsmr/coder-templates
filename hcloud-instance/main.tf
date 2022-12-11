terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.5"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.36.1"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "coder" {
}

variable "hcloud_token" {
  sensitive = true
}

variable "instance_location" {
  description = "Location for the Workspace"
  default     = "nbg1"
  validation {
    condition     = contains(["nbg1", "fsn1", "hel1", "ash"], var.instance_location)
    error_message = ""
  }
}

variable "instance_type" {
  default     = "cpx11"
  description = "Server type for the Workspace"
  validation {
    condition = contains([
      "cpx11", "cpx21", "cpx31", "cpx41", "cpx51"
    ], var.instance_type)
    error_message = ""
  }
}


variable "instance_os" {
  default     = "docker-ce"
  description = "Image for the Workspace"
  validation {
    condition = contains([
      "centos-7", "centos-stream-8", "centos-stream-9",
      "debian-10", "debian-11",
      "fedora-36",
      "rocky-8", "rocky-9",
      "ubuntu-18.04", "ubuntu-20.04", "ubuntu-22.04",
      "docker-ce"
    ], var.instance_os)
    error_message = ""
  }
}

variable "home_volume_size" {
  default     = "10"
  description = "Size of the persistent volume (In GB, 10 or more, /home/$owner)"
  validation {
    condition     = var.home_volume_size >= 10
    error_message = "Volume size has to be >= 10"
  }
}

data "coder_workspace" "me" {
}

resource "coder_agent" "dev" {
  arch = "amd64"
  os   = "linux"
}

resource "tls_private_key" "dummy" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "coder_metadata" "hide_keypair" {
  resource_id = tls_private_key.dummy.id
  hide        = true
}

resource "hcloud_ssh_key" "dummy" {
  name       = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}-dummy"
  public_key = tls_private_key.dummy.public_key_openssh
}

resource "coder_metadata" "hide_hcloud_key" {
  resource_id = hcloud_ssh_key.dummy.id
  hide        = true
}

resource "hcloud_firewall" "restricted" {
  name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}-restricted"
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "coder_metadata" "hide_firewall" {
  resource_id = hcloud_firewall.restricted.id
  hide        = true
}

resource "hcloud_volume" "home" {
  name     = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}-home"
  size     = var.home_volume_size
  format   = "ext4"
  location = var.instance_location
}

resource "coder_metadata" "volume_meta" {
  resource_id = hcloud_volume.home.id
  icon        = "/icon/folder.svg"
  item {
    key   = "size"
    value = "${var.home_volume_size} GB"
  }
}

resource "hcloud_server" "instance" {
  count       = data.coder_workspace.me.start_count
  name        = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
  server_type = var.instance_type
  location    = var.instance_location
  image       = var.instance_os
  ssh_keys    = [hcloud_ssh_key.dummy.id]
  user_data   = templatefile("cloud_init.yaml", {
    username          = data.coder_workspace.me.owner
    volume_path       = "/dev/disk/by-id/scsi-0HC_Volume_${hcloud_volume.home.id}"
    init_script       = base64encode(coder_agent.dev.init_script)
    coder_agent_token = coder_agent.dev.token
  })
}

resource "coder_metadata" "instance_meta" {
  count       = data.coder_workspace.me.start_count
  resource_id = hcloud_server.instance[0].id
  icon        = "/icon/memory.svg"
  item {
    key   = "instance_type"
    value = var.instance_type
  }
  item {
    key   = "instance_location"
    value = var.instance_location
  }
  item {
    key   = "instance_os"
    value = var.instance_os
  }
}

resource "hcloud_volume_attachment" "attach_home" {
  count     = data.coder_workspace.me.start_count
  volume_id = hcloud_volume.home.id
  server_id = hcloud_server.instance[0].id
  automount = false
}

resource "coder_metadata" "hide_attach_home" {
  count       = data.coder_workspace.me.start_count
  resource_id = hcloud_volume_attachment.attach_home[0].id
  hide        = true
}

resource "hcloud_firewall_attachment" "attach_firewall" {
  count       = data.coder_workspace.me.start_count
  firewall_id = hcloud_firewall.restricted.id
  server_ids  = [hcloud_server.instance[0].id]
}

resource "coder_metadata" "hide_attach_firewall" {
  count       = data.coder_workspace.me.start_count
  resource_id = hcloud_firewall_attachment.attach_firewall[0].id
  hide        = true
}
