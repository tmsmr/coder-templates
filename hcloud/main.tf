data "coder_provisioner" "me" {}

data "coder_workspace" "me" {}

data "coder_workspace_owner" "me" {}

locals {
  username = "coder"
}

resource "hcloud_server" "server" {
  count        = data.coder_workspace.me.start_count
  name         = "coder-${data.coder_workspace.me.name}"
  image        = split(";", data.coder_parameter.hcloud_server_os.value)[0]
  server_type  = data.coder_parameter.hcloud_server_type.value
  location     = data.coder_parameter.hcloud_location.value
  firewall_ids = [hcloud_firewall.drop_all.id]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  user_data = templatefile("cloud-config.yaml.tftpl", {
    username          = local.username
    home_volume_label = "coder-${data.coder_workspace.me.id}-home"
    volume_id         = hcloud_volume.volume.id
    init_script       = base64encode(coder_agent.agent.init_script)
    coder_agent_token = coder_agent.agent.token
  })
  labels = {
    "coder_workspace_name"  = data.coder_workspace.me.name,
    "coder_workspace_owner" = data.coder_workspace_owner.me.name,
  }

  lifecycle {
    precondition {
      condition     = local.hcloud_server_types[data.coder_parameter.hcloud_server_type.value].architecture == split(";", data.coder_parameter.hcloud_server_os.value)[1]
      error_message = "Selected OS architecture does not match server type architecture."
    }
  }
}

resource "hcloud_volume" "volume" {
  name     = "coder-${data.coder_workspace.me.id}-home"
  size     = data.coder_parameter.home_volume_size.value
  format   = "ext4"
  location = data.coder_parameter.hcloud_location.value
  labels = {
    "coder_workspace_name"  = data.coder_workspace.me.name,
    "coder_workspace_owner" = data.coder_workspace_owner.me.name,
  }
}

resource "hcloud_volume_attachment" "attachment" {
  count     = data.coder_workspace.me.start_count
  volume_id = hcloud_volume.volume.id
  server_id = hcloud_server.server[count.index].id
  automount = false
}

resource "coder_metadata" "hide_attachment" {
  count       = data.coder_workspace.me.start_count
  resource_id = hcloud_volume_attachment.attachment[count.index].id
  hide        = true
}

resource "coder_agent" "agent" {
  os   = "linux"
  arch = local.agent_arch

  metadata {
    display_name = "CPU Usage"
    key          = "cpu_usage"
    script       = "coder stat cpu"
    interval     = 5
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "ram_usage"
    script       = "coder stat mem"
    interval     = 5
    timeout      = 1
  }

  metadata {
    key          = "home"
    display_name = "Home Volume Usage"
    interval     = 60
    timeout      = 30
    script       = "coder stat disk --path /home/${local.username}"
  }
}
