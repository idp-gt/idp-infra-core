terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# --------------------------------------------------------------------------------------------------
# 1. GCP SIDE: HA VPN GATEWAY & CLOUD ROUTER
# --------------------------------------------------------------------------------------------------
resource "google_compute_ha_vpn_gateway" "gcp_ha_gw" {
  name    = "idp-gcp-ha-vpn-gw"
  network = var.gcp_network_id
  region  = var.gcp_region
  project = var.gcp_project_id
}

resource "google_compute_router" "gcp_router" {
  name    = var.gcp_router_name
  network = var.gcp_network_id
  region  = var.gcp_region
  project = var.gcp_project_id

  bgp {
    asn = var.gcp_bgp_asn
  }
}

# --------------------------------------------------------------------------------------------------
# 2. AWS SIDE: VIRTUAL PRIVATE GATEWAY & CUSTOMER GATEWAYS
# --------------------------------------------------------------------------------------------------
resource "aws_vpn_gateway" "aws_vgw" {
  vpc_id          = var.aws_vpc_id
  amazon_side_asn = var.aws_bgp_asn

  tags = {
    Name      = "idp-aws-vgw"
    Platform  = "idp-core"
    ManagedBy = "terraform"
  }
}

# Customer Gateway 1 (points to GCP HA VPN Interface 0)
resource "aws_customer_gateway" "gcp_gw_0" {
  bgp_asn    = var.gcp_bgp_asn
  ip_address = google_compute_ha_vpn_gateway.gcp_ha_gw.vpn_interfaces[0].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "idp-cgw-gcp-if0"
  }
}

# Customer Gateway 2 (points to GCP HA VPN Interface 1)
resource "aws_customer_gateway" "gcp_gw_1" {
  bgp_asn    = var.gcp_bgp_asn
  ip_address = google_compute_ha_vpn_gateway.gcp_ha_gw.vpn_interfaces[1].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "idp-cgw-gcp-if1"
  }
}

# AWS Site-to-Site VPN Connection to GCP Interface 0
resource "aws_vpn_connection" "cx_0" {
  vpn_gateway_id      = aws_vpn_gateway.aws_vgw.id
  customer_gateway_id = aws_customer_gateway.gcp_gw_0.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_preshared_key = var.shared_secret
  tunnel2_preshared_key = var.shared_secret

  tags = {
    Name = "idp-vpn-connection-0"
  }
}

# AWS Site-to-Site VPN Connection to GCP Interface 1
resource "aws_vpn_connection" "cx_1" {
  vpn_gateway_id      = aws_vpn_gateway.aws_vgw.id
  customer_gateway_id = aws_customer_gateway.gcp_gw_1.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_preshared_key = var.shared_secret
  tunnel2_preshared_key = var.shared_secret

  tags = {
    Name = "idp-vpn-connection-1"
  }
}

# --------------------------------------------------------------------------------------------------
# 3. GCP SIDE: EXTERNAL VPN GATEWAY & TUNNELS TO AWS
# --------------------------------------------------------------------------------------------------
resource "google_compute_external_vpn_gateway" "aws_external_gw" {
  name            = "idp-aws-external-gw"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  project         = var.gcp_project_id

  interface {
    id         = 0
    ip_address = aws_vpn_connection.cx_0.tunnel1_address
  }
  interface {
    id         = 1
    ip_address = aws_vpn_connection.cx_0.tunnel2_address
  }
  interface {
    id         = 2
    ip_address = aws_vpn_connection.cx_1.tunnel1_address
  }
  interface {
    id         = 3
    ip_address = aws_vpn_connection.cx_1.tunnel2_address
  }
}

# GCP Tunnel 1 (GCP Interface 0 -> AWS cx_0 tunnel 1)
resource "google_compute_vpn_tunnel" "tunnel_1" {
  name                            = "idp-tunnel-gcp-aws-1"
  region                          = var.gcp_region
  project                         = var.gcp_project_id
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_gw.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_external_gw.id
  peer_external_gateway_interface = 0
  shared_secret                   = var.shared_secret
  router                          = google_compute_router.gcp_router.id
}

# GCP Tunnel 2 (GCP Interface 1 -> AWS cx_1 tunnel 1)
resource "google_compute_vpn_tunnel" "tunnel_2" {
  name                            = "idp-tunnel-gcp-aws-2"
  region                          = var.gcp_region
  project                         = var.gcp_project_id
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_ha_gw.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_external_gw.id
  peer_external_gateway_interface = 2
  shared_secret                   = var.shared_secret
  router                          = google_compute_router.gcp_router.id
}

# BGP Interfaces and Peers on GCP Router
resource "google_compute_router_interface" "router_if_1" {
  name       = "idp-router-if-1"
  router     = google_compute_router.gcp_router.name
  region     = var.gcp_region
  project    = var.gcp_project_id
  ip_range   = "${aws_vpn_connection.cx_0.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_1.name
}

resource "google_compute_router_peer" "router_peer_1" {
  name                      = "idp-router-peer-aws-1"
  router                    = google_compute_router.gcp_router.name
  region                    = var.gcp_region
  project                   = var.gcp_project_id
  peer_ip_address           = aws_vpn_connection.cx_0.tunnel1_vgw_inside_address
  peer_asn                  = var.aws_bgp_asn
  interface                 = google_compute_router_interface.router_if_1.name
  advertised_route_priority = 100
}

resource "google_compute_router_interface" "router_if_2" {
  name       = "idp-router-if-2"
  router     = google_compute_router.gcp_router.name
  region     = var.gcp_region
  project    = var.gcp_project_id
  ip_range   = "${aws_vpn_connection.cx_1.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_2.name
}

resource "google_compute_router_peer" "router_peer_2" {
  name                      = "idp-router-peer-aws-2"
  router                    = google_compute_router.gcp_router.name
  region                    = var.gcp_region
  project                   = var.gcp_project_id
  peer_ip_address           = aws_vpn_connection.cx_1.tunnel1_vgw_inside_address
  peer_asn                  = var.aws_bgp_asn
  interface                 = google_compute_router_interface.router_if_2.name
  advertised_route_priority = 100
}

# --------------------------------------------------------------------------------------------------
# 4. OPTIONAL: INTRA-GCP VPC PEERING
# --------------------------------------------------------------------------------------------------
resource "google_compute_network_peering" "peering_hub_to_spoke" {
  count        = var.enable_vpc_peering && var.peer_network_id != null ? 1 : 0
  name         = "peer-hub-to-spoke"
  network      = var.gcp_network_id
  peer_network = var.peer_network_id

  export_custom_routes = true
  import_custom_routes = true
}

