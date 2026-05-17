terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    coder = {
      source = "coder/coder"
    }
    http = {
      source = "hashicorp/http"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}
