terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# --------------------------------------------------------------------------------------------------
# VPC NETWORK (Hub or Spoke)
# --------------------------------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = var.auto_create_subnetworks
  routing_mode            = var.routing_mode
  description             = var.description
}

# --------------------------------------------------------------------------------------------------
# SUBNETS (with secondary ranges for GKE Pods & Services)
# --------------------------------------------------------------------------------------------------
resource "google_compute_subnetwork" "subnets" {
  for_each = { for s in var.subnets : s.subnet_name => s }

  name                     = each.value.subnet_name
  ip_cidr_range            = each.value.subnet_ip
  region                   = each.value.subnet_region
  network                  = google_compute_network.vpc.id
  project                  = var.project_id
  private_ip_google_access = coalesce(each.value.subnet_private_access, true)
  description              = each.value.description

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ip_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  dynamic "log_config" {
    for_each = coalesce(each.value.subnet_flow_logs, false) ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

# --------------------------------------------------------------------------------------------------
# CLOUD ROUTER & CLOUD NAT (Outbound internet for private GKE & VMs)
# --------------------------------------------------------------------------------------------------
resource "google_compute_router" "router" {
  count   = var.create_cloud_nat ? 1 : 0
  name    = var.router_name
  region  = var.nat_region
  network = google_compute_network.vpc.id
  project = var.project_id

  bgp {
    asn = var.router_asn
  }
}

resource "google_compute_router_nat" "nat" {
  count                              = var.create_cloud_nat ? 1 : 0
  name                               = var.nat_name
  router                             = google_compute_router.router[0].name
  region                             = var.nat_region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# --------------------------------------------------------------------------------------------------
# FIREWALL RULES
# --------------------------------------------------------------------------------------------------

# Allow internal traffic between private subnets (RFC1918)
resource "google_compute_firewall" "allow_internal" {
  name        = "${var.network_name}-allow-internal"
  network     = google_compute_network.vpc.name
  project     = var.project_id
  description = "Allow internal traffic within private IP space for IDP services"

  source_ranges = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]

  allow {
    protocol = "all"
  }
}

# Allow SSH via Google Cloud Identity-Aware Proxy (IAP) - Zero direct public IP requirement
resource "google_compute_firewall" "allow_iap_ssh" {
  name        = "${var.network_name}-allow-iap-ssh"
  network     = google_compute_network.vpc.name
  project     = var.project_id
  description = "Allow Google Cloud IAP IP range for secure administrative bastion SSH"

  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# Allow GCP health check probes for Load Balancers (GKE Ingress / Gateway API)
resource "google_compute_firewall" "allow_health_checks" {
  name        = "${var.network_name}-allow-health-checks"
  network     = google_compute_network.vpc.name
  project     = var.project_id
  description = "Allow Google Cloud Load Balancer health check probes"

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443", "10254"]
  }
}

