variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region where simulated on-premises nodes reside"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone where simulated on-premises nodes reside"
  type        = string
  default     = "us-central1-a"
}

variable "subnetwork" {
  description = "Subnetwork self_link or name for on-prem simulated instances"
  type        = string
}

variable "instance_name_prefix" {
  description = "Prefix for instance names"
  type        = string
  default     = "onprem-sim"
}

variable "control_plane_count" {
  description = "Number of control plane / master nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "control_plane_machine_type" {
  description = "Machine type for control plane nodes"
  type        = string
  default     = "e2-standard-4" # 4 vCPU, 16 GB RAM (minimum recommended for Kubespray)
}

variable "worker_machine_type" {
  description = "Machine type for worker nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "image_family" {
  description = "OS Image family"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "image_project" {
  description = "OS Image project"
  type        = string
  default     = "ubuntu-os-cloud"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB for each node"
  type        = number
  default     = 50
}

variable "ssh_user" {
  description = "Default SSH username for Ansible management"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key string for accessing instances"
  type        = string
  default     = ""
}

variable "generate_inventory_file" {
  description = "Whether to write an Ansible hosts.ini inventory file directly to disk"
  type        = bool
  default     = true
}

variable "inventory_output_path" {
  description = "Path where the Ansible hosts.ini file will be rendered"
  type        = string
  default     = "../../ansible/inventories/gce-onprem-sim/hosts.ini"
}

