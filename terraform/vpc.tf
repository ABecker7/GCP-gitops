resource "random_id" "cluster_suffix" {
  byte_length = 4
}

# VPC Network

resource "google_compute_network" "vpc" {
  name = "${var.network_name}-${random_id.cluster_suffix.hex}"

  auto_create_subnetworks         = false
  delete_default_routes_on_create = false

  description = "VPC network for GKE cluster with security hardening"

  routing_mode = "REGIONAL"
}

# Subnet for GKE Nodes
resource "google_compute_subnetwork" "subnet" {
  name = "${var.subnet_name}-${random_id.cluster_suffix.hex}"

  ip_cidr_range = "10.0.0.0/20"

  region  = var.region
  network = google_compute_network.vpc.id

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_ipv4_cidr_block
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_ipv4_cidr_block
  }

  description = "Subnet for GKE nodes with secondary ranges for pods and services"
}


# Cloud Router & NAT
resource "google_compute_router" "router" {
  name    = "google-router-${random_id.cluster_suffix.hex}"
  region  = var.region
  network = google_compute_network.vpc.id

  bgp {
    asn = 64514
  }
}


# Cloud NAT
resource "google_compute_router_nat" "nat" {
  name   = "gke-nat-${random_id.cluster_suffix.hex}"
  router = google_compute_router.router.name
  region = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
