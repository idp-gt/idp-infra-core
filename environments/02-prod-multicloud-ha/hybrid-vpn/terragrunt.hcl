include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/hybrid-interconnect"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# --------------------------------------------------------------------------------------------------
# Dependencias automáticas: Lee outputs de gcp-vpc y aws-vpc-eks sin duplicar configuración
# --------------------------------------------------------------------------------------------------
dependency "gcp_vpc" {
  config_path = "../gcp-vpc"

  mock_outputs = {
    network_id = "projects/mock-project/global/networks/idp-gcp-prod-vpc"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "aws_vpc_eks" {
  config_path = "../aws-vpc-eks"

  mock_outputs = {
    vpc_id = "vpc-0123456789abcdef0"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  gcp_project_id  = local.env_vars.locals.gcp_project_id
  gcp_region      = local.env_vars.locals.gcp_region
  gcp_network_id  = dependency.gcp_vpc.outputs.network_id
  gcp_router_name = "idp-gcp-aws-router"
  gcp_bgp_asn     = local.env_vars.locals.gcp_bgp_asn

  aws_vpc_id    = dependency.aws_vpc_eks.outputs.vpc_id
  aws_bgp_asn   = local.env_vars.locals.aws_bgp_asn
  shared_secret = local.env_vars.locals.vpn_preshared_key
}

