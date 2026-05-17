module "jetbrains" {
  source = "registry.coder.com/coder/jetbrains/coder"
  count  = data.coder_workspace.me.start_count

  version  = "1.4.0"
  agent_id = coder_agent.agent.id
  default  = ["IU", "PY"]
  folder   = "/home/${local.username}/projects"
}

module "opencode" {
  source = "registry.coder.com/coder-labs/opencode/coder"
  count  = data.coder_workspace.me.start_count

  version  = "0.1.2"
  agent_id = coder_agent.agent.id
  workdir  = "/home/${local.username}/projects"
}
