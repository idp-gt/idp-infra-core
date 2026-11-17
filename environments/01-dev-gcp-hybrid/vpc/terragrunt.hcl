include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/gcp-vpc"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  project_id   = local.env_vars.locals.project_id
  network_name = local.env_vars.locals.network_name
  nat_region   = local.env_vars.locals.region

  subnets = [
    {
      subnet_name   = "snet-gke-dev"
      subnet_ip     = local.env_vars.locals.subnet_gke_cidr
      subnet_region = local.env_vars.locals.region
      description   = "GKE Dev Cluster Subnet"
      secondary_ip_ranges = [
        {
          range_name    = "gke-pods-range"
          ip_cidr_range = local.env_vars.locals.subnet_gke_pods_cidr
        },
        {
          range_name    = "gke-services-range"
          ip_cidr_range = local.env_vars.locals.subnet_gke_services_cidr
        }
      ]
    },
    {
      subnet_name   = "snet-onprem-sim"
      subnet_ip     = local.env_vars.locals.subnet_onprem_cidr
      subnet_region = local.env_vars.locals.region
      description   = "Subnet simulating On-Premises bare metal datacenter"
    }
  ]
}

