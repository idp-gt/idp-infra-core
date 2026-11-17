# ==============================================================================
# Terragrunt Root Configuration (DRY Remote State & Providers)
# ==============================================================================

locals {
  # Automatically load environment-level variables from env.hcl in parent folders
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Normalize environment variables across single-cloud and multi-cloud configs
  environment    = try(local.env_vars.locals.environment, "dev")
  gcp_project_id = try(local.env_vars.locals.gcp_project_id, local.env_vars.locals.project_id)
  gcp_region     = try(local.env_vars.locals.gcp_region, local.env_vars.locals.region, "us-central1")
  aws_region     = try(local.env_vars.locals.aws_region, "")
}

# --------------------------------------------------------------------------------------------------
# Remote State Configuration (GCS Bucket per project/environment)
# --------------------------------------------------------------------------------------------------
remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    project  = local.gcp_project_id
    location = local.gcp_region
    bucket   = "${local.gcp_project_id}-tfstate-${local.environment}"
    prefix   = "${path_relative_to_include()}/terraform.tfstate"
    gcs_bucket_labels = {
      managed_by  = "terragrunt"
      environment = local.environment
      platform    = "idp-core"
    }
  }
}

# --------------------------------------------------------------------------------------------------
# Generate Provider Configurations (Google Cloud & AWS)
# --------------------------------------------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"
}

provider "google" {
  project = "${local.gcp_project_id}"
  region  = "${local.gcp_region}"
}

%{if local.aws_region != ""~}
provider "aws" {
  region = "${local.aws_region}"
}
%{endif~}
EOF
}

# Pass common variables down to all modules automatically
inputs = merge(
  local.env_vars.locals,
  {
    environment = local.environment
  }
)

