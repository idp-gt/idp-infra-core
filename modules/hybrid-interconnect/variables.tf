variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for HA VPN Gateway and Cloud Router"
  type        = string
  default     = "us-central1"
}

variable "gcp_network_id" {
  description = "GCP VPC Network ID or self_link"
  type        = string
}

variable "gcp_router_name" {
  description = "Name for GCP Cloud Router"
  type        = string
  default     = "idp-gcp-aws-router"
}

variable "gcp_bgp_asn" {
  description = "BGP Autonomous System Number (ASN) for GCP Cloud Router"
  type        = number
  default     = 64514
}

variable "aws_vpc_id" {
  description = "AWS VPC ID to connect"
  type        = string
}

variable "aws_bgp_asn" {
  description = "BGP Autonomous System Number (ASN) for AWS Virtual Private Gateway"
  type        = number
  default     = 64515
}

variable "shared_secret" {
  description = "Pre-shared key (PSK) secret for IPsec tunnels"
  type        = string
  sensitive   = true
  default     = "IdpMultiCloudSecurePresharedKey2026!"
}

variable "enable_vpc_peering" {
  description = "Whether to create internal GCP VPC peering (if connecting multiple GCP VPCs)"
  type        = bool
  default     = false
}

variable "peer_network_id" {
  description = "Target VPC network ID for internal peering if enabled"
  type        = string
  default     = null
}

