resource "hcloud_firewall" "drop_all" {
  name = "coder-${data.coder_workspace.me.name}"
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0"
    ]
  }
}

resource "coder_metadata" "hide_firewall" {
  resource_id = hcloud_firewall.drop_all.id
  hide        = true
}
