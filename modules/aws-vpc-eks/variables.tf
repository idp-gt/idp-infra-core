variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "idp-aws-dr-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR block for AWS VPC (non-overlapping with GCP CIDR space)"
  type        = string
  default     = "10.50.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones in the AWS region"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets_cidr" {
  description = "CIDR blocks for private subnets (where EKS worker nodes run)"
  type        = list(string)
  default     = ["10.50.10.0/24", "10.50.20.0/24"]
}

variable "public_subnets_cidr" {
  description = "CIDR blocks for public subnets (where NAT Gateways and external LBs run)"
  type        = list(string)
  default     = ["10.50.1.0/24", "10.50.2.0/24"]
}

variable "single_nat_gateway" {
  description = "Whether to deploy a single NAT Gateway (cost-saving for dev/lab) or one per AZ (prod HA)"
  type        = bool
  default     = true
}

variable "node_group_instance_types" {
  description = "EC2 instance types for EKS managed node group"
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_group_scaling_config" {
  description = "Autoscaling configuration for default node group"
  type = object({
    desired_size = number
    max_size     = number
    min_size     = number
  })
  default = {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "prod-multicloud-ha"
    Platform    = "idp-core"
    ManagedBy   = "terraform"
  }
}

