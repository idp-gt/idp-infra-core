# Environment-wide variables for Dev GCP Hybrid
locals {
  environment = "dev"
  project_id  = "idp-dev-platform-core" # Cambiar por tu GCP Project ID real
  region      = "us-central1"
  zone        = "us-central1-a"

  # Network CIDRs
  network_name             = "idp-dev-vpc"
  subnet_gke_cidr          = "10.10.0.0/20"
  subnet_gke_pods_cidr     = "10.11.0.0/16"
  subnet_gke_services_cidr = "10.12.0.0/20"
  subnet_onprem_cidr       = "10.10.32.0/24"
}

