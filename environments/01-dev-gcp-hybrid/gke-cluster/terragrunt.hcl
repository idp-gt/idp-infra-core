include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/gcp-gke-cluster"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    network_self_link = "projects/mock-project/global/networks/mock-vpc"
    subnets = {
      snet-gke-dev = {
        self_link = "projects/mock-project/regions/us-central1/subnetworks/snet-gke-dev"
      }
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  project_id        = local.env_vars.locals.project_id
  cluster_name      = "idp-gke-dev"
  location          = local.env_vars.locals.region
  network           = dependency.vpc.outputs.network_self_link
  subnetwork        = dependency.vpc.outputs.subnets["snet-gke-dev"].self_link
  ip_range_pods     = "gke-pods-range"
  ip_range_services = "gke-services-range"

  enable_base_pool = true
  enable_data_pool = true
  enable_ai_pool   = false # Cambiar a true para desplegar GPU L4

  cluster_labels = {
    environment = local.env_vars.locals.environment
    managed-by  = "terragrunt"
    topology    = "hybrid-hub"
  }
}

