variable "project_id" {
  description = "The GCP Project ID where the network resources will be created"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
  default     = "idp-hub-vpc"
}

variable "routing_mode" {
  description = "The network routing mode (GLOBAL or REGIONAL)"
  type        = string
  default     = "GLOBAL"
}

variable "description" {
  description = "An optional description of this VPC resource"
  type        = string
  default     = "IDP Core Hub VPC Network"
}

variable "auto_create_subnetworks" {
  description = "Whether to create auto subnets (recommended: false for custom enterprise topology)"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "List of subnets to create with their CIDR, region, and optional secondary ranges (for GKE)"
  type = list(object({
    subnet_name           = string
    subnet_ip             = string
    subnet_region         = string
    subnet_private_access = optional(bool, true)
    subnet_flow_logs      = optional(bool, false)
    description           = optional(string, "IDP Subnet")
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
  }))
  default = []
}

variable "create_cloud_nat" {
  description = "Whether to provision Cloud Router and Cloud NAT for private subnets outbound internet access"
  type        = bool
  default     = true
}

variable "nat_region" {
  description = "Region where Cloud NAT and Router are deployed"
  type        = string
  default     = "us-central1"
}

variable "nat_name" {
  description = "Name of the Cloud NAT gateway"
  type        = string
  default     = "idp-nat-gw"
}

variable "router_name" {
  description = "Name of the Cloud Router"
  type        = string
  default     = "idp-cloud-router"
}

variable "router_asn" {
  description = "Local BGP Autonomous System Number (ASN) for Cloud Router"
  type        = number
  default     = 64514
}

