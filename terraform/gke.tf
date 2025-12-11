# GKE Cluster 

resource "google_container_cluster" "primary" {
  name     = "${var.cluster_name}-${random_id.cluster_suffix.hex}"
  location = var.region

  deletion_protection = false
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }



  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = false
    }
    gcp_filestore_csi_driver_config {
      enabled = false
    }
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  release_channel {
    channel = "REGULAR"
  }


  #  logging_config {
  #    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  #  }
  #
  #monitoring_config {
  #  enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  #  managed_prometheus {
  #    enabled = true
  #  }
  #}

  resource_labels = {
    environment = "production"
    managed_by  = "terraform"
    team        = "platform"
  }


  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }

  notification_config {
    pubsub {
      enabled = true
      topic   = google_pubsub_topic.gke_notifications.id
    }
  }

  depends_on = [
    google_compute_router_nat.nat
  ]
}

resource "google_pubsub_topic" "gke_notifications" {
  name                       = "gke-cluster-notifications-${random_id.cluster_suffix.hex}"
  message_retention_duration = "86400s"
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  autoscaling {
    min_node_count = 1
    max_node_count = 2
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    image_type   = "COS_CONTAINERD"

    service_account = google_service_account.gke_nodes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disabled-legacy-endpoints = "true"
    }

    labels = {
      environment = "production"
      node_pool   = "primary"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    kubelet_config {
      cpu_manager_policy = "static"
      cpu_cfs_quota      = true
      pod_pids_limit     = 4096
    }
  }

  lifecycle {
    ignore_changes = [node_count]
  }
}

resource "google_compute_firewall" "allow_internal" {
  name    = "gke-allow-internal-${random_id.cluster_suffix.hex}"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [
    google_compute_subnetwork.subnet.ip_cidr_range,
    google_compute_subnetwork.subnet.secondary_ip_range[0].ip_cidr_range,
    google_compute_subnetwork.subnet.secondary_ip_range[1].ip_cidr_range,
  ]

  description = "Allow internal communications within VPC for GKE"
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "gke-allow-health-checks-${random_id.cluster_suffix.hex}"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
  ]

  description = "Allow health checks from Google Cloud load balancers"
}

