output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "The URI of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnets" {
  description = "Map of created subnet details"
  value = {
    for k, s in google_compute_subnetwork.subnets : k => {
      id                  = s.id
      name                = s.name
      region              = s.region
      ip_cidr_range       = s.ip_cidr_range
      self_link           = s.self_link
      secondary_ip_ranges = s.secondary_ip_range
    }
  }
}

output "router_name" {
  description = "The name of the Cloud Router (if NAT was created)"
  value       = try(google_compute_router.router[0].name, null)
}

output "router_id" {
  description = "The ID of the Cloud Router"
  value       = try(google_compute_router.router[0].id, null)
}

