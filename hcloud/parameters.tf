data "coder_parameter" "hcloud_location" {
  name         = "hcloud_location"
  display_name = "Hetzner Cloud Location"
  description  = "Select the Hetzner Cloud location for your workspace."
  type         = "string"
  default      = "fsn1"

  dynamic "option" {
    for_each = local.hcloud_locations
    content {
      name = format(
        "%s (%s, %s)",
        upper(option.value.name),
        option.value.city,
        option.value.country
      )
      value = option.value.name
    }
  }
}

data "coder_parameter" "hcloud_server_type" {
  name         = "hcloud_server_type"
  display_name = "Hetzner Cloud Server Type"
  description  = "Select the Hetzner Cloud server type for your workspace."
  type         = "string"
  default      = "cpx42"

  dynamic "option" {
    for_each = local.hcloud_server_type_options_for_selected_location
    content {
      name  = option.value.name
      value = option.value.value
    }
  }
}

data "coder_parameter" "hcloud_server_os" {
  name         = "hcloud_server_os"
  display_name = "Hetzner Cloud Server OS"
  description  = "Select the OS for your workspace."
  type         = "string"
  default      = "ubuntu-24.04;x86"
  mutable      = false

  dynamic "option" {
    for_each = local.hcloud_images
    content {
      name  = "${option.value.description} (${upper(option.value.architecture)})"
      value = "${option.value.name};${option.value.architecture}"
    }
  }
}


data "coder_parameter" "home_volume_size" {
  name         = "home_volume_size"
  display_name = "Home Volume Size"
  description  = "How large would you like your home volume to be (in GB)?"
  type         = "number"
  default      = "20"
  mutable      = false
  validation {
    min = 1
    max = 500
  }
}
