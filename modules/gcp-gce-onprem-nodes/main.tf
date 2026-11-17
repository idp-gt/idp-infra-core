terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# --------------------------------------------------------------------------------------------------
# Control Plane Instances (Simulating On-Premises Bare-Metal Master Nodes)
# --------------------------------------------------------------------------------------------------
resource "google_compute_instance" "control_plane" {
  count        = var.control_plane_count
  name         = "${var.instance_name_prefix}-cp-${count.index + 1}"
  machine_type = var.control_plane_machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["onprem-sim", "k8s-control-plane"]

  boot_disk {
    initialize_params {
      image = "${var.image_project}/${var.image_family}"
      size  = var.boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnetwork
    # In a simulated on-prem environment behind Cloud NAT, nodes only need internal IPs
    # or an ephemeral external IP if direct SSH without IAP is preferred.
    access_config {
      // Ephemeral public IP for easy ansible access or can be omitted if using IAP tunnel
    }
  }

  metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = var.ssh_public_key != "" ? "${var.ssh_user}:${var.ssh_public_key}" : null
  }

  labels = {
    role        = "control-plane"
    environment = "onprem-sim"
    managed-by  = "terraform"
  }
}

# --------------------------------------------------------------------------------------------------
# Worker Node Instances (Simulating On-Premises Bare-Metal Worker Nodes)
# --------------------------------------------------------------------------------------------------
resource "google_compute_instance" "workers" {
  count        = var.worker_count
  name         = "${var.instance_name_prefix}-worker-${count.index + 1}"
  machine_type = var.worker_machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["onprem-sim", "k8s-worker"]

  boot_disk {
    initialize_params {
      image = "${var.image_project}/${var.image_family}"
      size  = var.boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnetwork
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = var.ssh_public_key != "" ? "${var.ssh_user}:${var.ssh_public_key}" : null
  }

  labels = {
    role        = "worker"
    environment = "onprem-sim"
    managed-by  = "terraform"
  }
}

# --------------------------------------------------------------------------------------------------
# Dynamic Inventory Generation for Kubespray / Ansible
# --------------------------------------------------------------------------------------------------
resource "local_file" "ansible_inventory" {
  count    = var.generate_inventory_file ? 1 : 0
  filename = var.inventory_output_path

  content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    control_planes = google_compute_instance.control_plane
    workers        = google_compute_instance.workers
    ssh_user       = var.ssh_user
  })
}

