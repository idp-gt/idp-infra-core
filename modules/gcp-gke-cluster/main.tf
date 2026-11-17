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
# Dedicated Service Account for GKE Nodes (Least Privilege)
# --------------------------------------------------------------------------------------------------
resource "google_service_account" "gke_sa" {
  account_id   = "${substr(var.cluster_name, 0, 24)}-sa"
  display_name = "Service Account for GKE Cluster ${var.cluster_name}"
  project      = var.project_id
}

resource "google_project_iam_member" "gke_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# --------------------------------------------------------------------------------------------------
# GKE Control Plane (VPC-Native, Private Cluster, Workload Identity)
# --------------------------------------------------------------------------------------------------
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.location
  project  = var.project_id

  # Manage node pools separately for zero-downtime upgrades
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = var.deletion_protection

  network    = var.network
  subnetwork = var.subnetwork

  ip_allocation_policy {
    cluster_secondary_range_name  = var.ip_range_pods
    services_secondary_range_name = var.ip_range_services
  }

  release_channel {
    channel = var.release_channel
  }

  min_master_version = var.min_master_version

  # Private Cluster Configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # Public endpoint with authorized networks restriction
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  datapath_provider = "ADVANCED_DATAPATH" # Google Cloud Cilium-based Datapath v2

  addons_config {
    http_load_balancing {
      disabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    gcp_filestore_csi_driver_config {
      enabled = true
    }
  }

  resource_labels = var.cluster_labels

  lifecycle {
    ignore_changes = [
      node_pool,
      initial_node_count,
    ]
  }
}

# --------------------------------------------------------------------------------------------------
# PROFILE 1: Base Node Pool (General Workloads & Core Platform Services)
# --------------------------------------------------------------------------------------------------
resource "google_container_node_pool" "base_pool" {
  count          = var.enable_base_pool ? 1 : 0
  name           = "pool-base"
  location       = var.location
  cluster        = google_container_cluster.primary.name
  project        = var.project_id
  node_locations = var.base_pool_config.node_locations

  autoscaling {
    min_node_count = var.base_pool_config.min_count
    max_node_count = var.base_pool_config.max_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.base_pool_config.machine_type
    disk_size_gb = var.base_pool_config.disk_size_gb
    disk_type    = var.base_pool_config.disk_type
    spot         = var.base_pool_config.spot

    service_account = google_service_account.gke_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = merge(var.cluster_labels, {
      "node.idp.io/profile" = "base"
    })

    metadata = {
      disable-legacy-endpoints = "true"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}

# --------------------------------------------------------------------------------------------------
# PROFILE 2: Data Node Pool (Stateful: Kafka, Databases, In-Memory Caches)
# --------------------------------------------------------------------------------------------------
resource "google_container_node_pool" "data_pool" {
  count          = var.enable_data_pool ? 1 : 0
  name           = "pool-data"
  location       = var.location
  cluster        = google_container_cluster.primary.name
  project        = var.project_id
  node_locations = var.data_pool_config.node_locations

  autoscaling {
    min_node_count = var.data_pool_config.min_count
    max_node_count = var.data_pool_config.max_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.data_pool_config.machine_type
    disk_size_gb = var.data_pool_config.disk_size_gb
    disk_type    = var.data_pool_config.disk_type
    spot         = var.data_pool_config.spot

    service_account = google_service_account.gke_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = merge(var.cluster_labels, {
      "node.idp.io/profile"  = "data"
      "workload.idp.io/tier" = "stateful"
    })

    taint {
      key    = "workload.idp.io/data"
      value  = "true"
      effect = "NO_SCHEDULE"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}

# --------------------------------------------------------------------------------------------------
# PROFILE 3: AI / GPU Node Pool (Model Inference, Fine-Tuning, Ollama, vLLM)
# --------------------------------------------------------------------------------------------------
resource "google_container_node_pool" "ai_pool" {
  count          = var.enable_ai_pool ? 1 : 0
  name           = "pool-ai-gpu"
  location       = var.location
  cluster        = google_container_cluster.primary.name
  project        = var.project_id
  node_locations = var.ai_pool_config.node_locations

  autoscaling {
    min_node_count = var.ai_pool_config.min_count
    max_node_count = var.ai_pool_config.max_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.ai_pool_config.machine_type
    disk_size_gb = var.ai_pool_config.disk_size_gb
    disk_type    = var.ai_pool_config.disk_type
    spot         = var.ai_pool_config.spot

    guest_accelerator {
      type  = var.ai_pool_config.gpu_type
      count = var.ai_pool_config.gpu_count
      gpu_driver_installation_config {
        gpu_driver_version = "DEFAULT"
      }
    }

    service_account = google_service_account.gke_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = merge(var.cluster_labels, {
      "node.idp.io/profile"    = "ai"
      "accelerator.idp.io/gpu" = var.ai_pool_config.gpu_type
    })

    taint {
      key    = "nvidia.com/gpu"
      value  = "present"
      effect = "NO_SCHEDULE"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}
