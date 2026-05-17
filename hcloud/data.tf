data "http" "hcloud_locations" {
  url = "https://api.hetzner.cloud/v1/locations?per_page=50"

  request_headers = {
    Authorization = "Bearer ${var.hcloud_token}"
    Accept        = "application/json"
  }
}

locals {
  hcloud_locations = [
    for loc in jsondecode(data.http.hcloud_locations.response_body).locations : {
      name         = loc.name
      description  = loc.description
      city         = loc.city
      country      = loc.country
      network_zone = loc.network_zone
    }
  ]
}

data "http" "hcloud_server_types" {
  url = "https://api.hetzner.cloud/v1/server_types?per_page=50"

  request_headers = {
    Authorization = "Bearer ${var.hcloud_token}"
    Accept        = "application/json"
  }
}

locals {
  hcloud_server_types = {
    for st in jsondecode(data.http.hcloud_server_types.response_body).server_types :
    st.name => {
      description  = st.description
      cores        = st.cores
      memory_gb    = st.memory
      disk_gb      = st.disk
      architecture = st.architecture
      locations    = [for l in st.locations : l.name]
      deprecated   = st.deprecated
    }
    if st.deprecated == false
  }

  hcloud_server_type_options_for_selected_location = [
    for name, meta in local.hcloud_server_types : {
      name = format(
        "%s (%s, %d vCPU's, %dGB RAM, %dGB Disk)",
        meta.description,
        upper(meta.architecture),
        meta.cores,
        meta.memory_gb,
        meta.disk_gb
      )
      value = name
    }
    if contains(
      meta.locations,
      data.coder_parameter.hcloud_location.value
    )
  ]
}

data "http" "hcloud_system_images" {
  url = "https://api.hetzner.cloud/v1/images?type=system&status=available&include_deprecated=false&per_page=50"

  request_headers = {
    Authorization = "Bearer ${var.hcloud_token}"
    Accept        = "application/json"
  }
}

data "http" "hcloud_app_images" {
  url = "https://api.hetzner.cloud/v1/images?type=app&status=available&include_deprecated=false&per_page=50"

  request_headers = {
    Authorization = "Bearer ${var.hcloud_token}"
    Accept        = "application/json"
  }
}

locals {
  hcloud_images = {
    for img in concat(
      jsondecode(data.http.hcloud_system_images.response_body).images,
      [for app in jsondecode(data.http.hcloud_app_images.response_body).images : app if app.name == "docker-ce"]
    ) :
    img.id => {
      name         = img.name
      description  = img.description
      architecture = img.architecture
    }
    if contains(["debian", "ubuntu"], img.os_flavor)
  }
}

locals {
  agent_arch = lookup(
    {
      "x86" = "amd64"
      "arm" = "arm64"
    },
    local.hcloud_server_types[data.coder_parameter.hcloud_server_type.value].architecture
  )
}
