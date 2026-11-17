include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/gcp-gce-onprem-nodes"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    subnets = {
      snet-onprem-sim = {
        self_link = "projects/mock-project/regions/us-central1/subnetworks/snet-onprem-sim"
      }
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  project_id              = local.env_vars.locals.project_id
  region                  = local.env_vars.locals.region
  zone                    = local.env_vars.locals.zone
  subnetwork              = dependency.vpc.outputs.subnets["snet-onprem-sim"].self_link
  instance_name_prefix    = "onprem-sim"
  control_plane_count     = 1
  worker_count            = 2
  ssh_user                = "ubuntu"
  ssh_public_key          = "" # Agregar clave SSH pública si se requiere acceso directo
  generate_inventory_file = true
  inventory_output_path   = "${get_repo_root()}/ansible/inventories/gce-onprem-sim/hosts.ini"
}

