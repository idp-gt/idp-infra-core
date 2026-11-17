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
  project_id   = local.env_vars.locals.gcp_project_id
  network_name = local.env_vars.locals.gcp_network_name
  nat_region   = local.env_vars.locals.gcp_region
  router_asn   = local.env_vars.locals.gcp_bgp_asn

  subnets = [
    {
      subnet_name   = "snet-gke-prod"
      subnet_ip     = local.env_vars.locals.gcp_subnet_cidr
      subnet_region = local.env_vars.locals.gcp_region
      description   = "GCP GKE Regional Prod Subnet"
      secondary_ip_ranges = [
        {
          range_name    = "gke-prod-pods"
          ip_cidr_range = local.env_vars.locals.gcp_pods_cidr
        },
        {
          range_name    = "gke-prod-services"
          ip_cidr_range = local.env_vars.locals.gcp_services_cidr
        }
      ]
    }
  ]
}

