output "gcp_ha_vpn_gateway_id" {
  description = "The ID of the GCP HA VPN gateway"
  value       = google_compute_ha_vpn_gateway.gcp_ha_gw.id
}

output "gcp_ha_vpn_interfaces" {
  description = "Public IP addresses allocated for GCP HA VPN Gateway"
  value       = google_compute_ha_vpn_gateway.gcp_ha_gw.vpn_interfaces[*].ip_address
}

output "aws_vpn_gateway_id" {
  description = "The ID of the AWS Virtual Private Gateway"
  value       = aws_vpn_gateway.aws_vgw.id
}

output "aws_vpn_connection_ids" {
  description = "IDs of the AWS Site-to-Site VPN connections"
  value = [
    aws_vpn_connection.cx_0.id,
    aws_vpn_connection.cx_1.id
  ]
}

output "bgp_status" {
  description = "Summary of configured BGP Peering"
  value = {
    gcp_asn             = var.gcp_bgp_asn
    aws_asn             = var.aws_bgp_asn
    tunnel_1_inside_gcp = aws_vpn_connection.cx_0.tunnel1_cgw_inside_address
    tunnel_1_inside_aws = aws_vpn_connection.cx_0.tunnel1_vgw_inside_address
    tunnel_2_inside_gcp = aws_vpn_connection.cx_1.tunnel1_cgw_inside_address
    tunnel_2_inside_aws = aws_vpn_connection.cx_1.tunnel1_vgw_inside_address
  }
}
