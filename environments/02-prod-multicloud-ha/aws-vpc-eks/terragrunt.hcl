include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/aws-vpc-eks"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  aws_region         = local.env_vars.locals.aws_region
  cluster_name       = local.env_vars.locals.aws_cluster_name
  vpc_cidr           = local.env_vars.locals.aws_vpc_cidr
  single_nat_gateway = false # High Availability con NAT Gateways multi-AZ en producción

  node_group_scaling_config = {
    desired_size = 3
    max_size     = 10
    min_size     = 3
  }

  tags = {
    Environment = local.env_vars.locals.environment
    Role        = "backup-dr-spoke"
    ManagedBy   = "terragrunt"
  }
}

