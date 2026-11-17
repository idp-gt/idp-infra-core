# Environment-wide variables for Prod Multi-Cloud HA (GCP + AWS)
locals {
  environment    = "prod"
  gcp_project_id = "idp-prod-platform-core" # Cambiar por tu GCP Project ID real
  gcp_region     = "us-central1"
  aws_region     = "us-east-1"

  # GCP Networking & GKE
  gcp_network_name  = "idp-gcp-prod-vpc"
  gcp_subnet_cidr   = "10.20.0.0/20"
  gcp_pods_cidr     = "10.21.0.0/16"
  gcp_services_cidr = "10.22.0.0/20"
  gcp_cluster_name  = "idp-gke-prod-ha"
  gcp_bgp_asn       = 64514

  # AWS Networking & EKS
  aws_cluster_name = "idp-aws-prod-eks"
  aws_vpc_cidr     = "10.50.0.0/16"
  aws_bgp_asn      = 64515

  # VPN IPSec Security
  vpn_preshared_key = "IdpMultiCloudSecurePresharedKey2026!"
}

