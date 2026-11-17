include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/gcp-gke-cluster"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "gcp_vpc" {
  config_path = "../gcp-vpc"

  mock_outputs = {
    network_self_link = "projects/mock-project/global/networks/mock-vpc"
    subnets = {
      snet-gke-prod = {
        self_link = "projects/mock-project/regions/us-central1/subnetworks/snet-gke-prod"
      }
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  project_id        = local.env_vars.locals.gcp_project_id
  cluster_name      = local.env_vars.locals.gcp_cluster_name
  location          = local.env_vars.locals.gcp_region # Clúster regional Multi-AZ
  network           = dependency.gcp_vpc.outputs.network_self_link
  subnetwork        = dependency.gcp_vpc.outputs.subnets["snet-gke-prod"].self_link
  ip_range_pods     = "gke-prod-pods"
  ip_range_services = "gke-prod-services"

  enable_base_pool = true
  enable_data_pool = true
  enable_ai_pool   = false

  base_pool_config = {
    machine_type   = "e2-standard-4"
    min_count      = 3
    max_count      = 10
    disk_size_gb   = 100
    disk_type      = "pd-balanced"
    spot           = false
    node_locations = null
  }

  data_pool_config = {
    machine_type   = "n2-standard-8"
    min_count      = 3
    max_count      = 6
    disk_size_gb   = 250
    disk_type      = "pd-ssd"
    spot           = false
    node_locations = null
  }

  cluster_labels = {
    environment = local.env_vars.locals.environment
    role        = "primary-hub"
    managed-by  = "terragrunt"
  }
}

