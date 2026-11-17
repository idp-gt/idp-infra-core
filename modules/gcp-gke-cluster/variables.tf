variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "location" {
  description = "The region (for regional cluster) or zone (for zonal cluster)"
  type        = string
  default     = "us-central1"
}

variable "network" {
  description = "The VPC network self_link or name"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork self_link or name"
  type        = string
}

variable "ip_range_pods" {
  description = "The name of the secondary subnet range to use for pods"
  type        = string
}

variable "ip_range_services" {
  description = "The name of the secondary subnet range to use for services"
  type        = string
}

variable "release_channel" {
  description = "The GKE release channel (REGULAR, RAPID, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "min_master_version" {
  description = "Minimum master version (optional)"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Whether to prevent Terraform from destroying the cluster"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "The /28 CIDR block for GKE master nodes private endpoint"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "List of CIDR blocks permitted to access the master control plane"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "Global Authorized (Demo/Dev) - Restrict in Prod"
    }
  ]
}

# --- Profiles toggles and configurations ---

# 1. Base Node Pool
variable "enable_base_pool" {
  description = "Enable standard/general-purpose node pool"
  type        = bool
  default     = true
}

variable "base_pool_config" {
  description = "Configuration for standard base node pool"
  type = object({
    machine_type   = string
    min_count      = number
    max_count      = number
    disk_size_gb   = number
    disk_type      = string
    spot           = bool
    node_locations = optional(list(string))
  })
  default = {
    machine_type   = "e2-standard-4"
    min_count      = 1
    max_count      = 5
    disk_size_gb   = 100
    disk_type      = "pd-balanced"
    spot           = false
    node_locations = null
  }
}

# 2. Data Node Pool
variable "enable_data_pool" {
  description = "Enable high-performance / memory-optimized node pool for Data services (Kafka, DBs, Vector DBs)"
  type        = bool
  default     = false
}

variable "data_pool_config" {
  description = "Configuration for data workloads node pool"
  type = object({
    machine_type   = string
    min_count      = number
    max_count      = number
    disk_size_gb   = number
    disk_type      = string
    spot           = bool
    node_locations = optional(list(string))
  })
  default = {
    machine_type   = "n2-standard-8"
    min_count      = 0
    max_count      = 3
    disk_size_gb   = 200
    disk_type      = "pd-ssd"
    spot           = false
    node_locations = null
  }
}

# 3. AI / GPU Node Pool
variable "enable_ai_pool" {
  description = "Enable GPU-accelerated node pool for AI/ML inference and fine-tuning workloads"
  type        = bool
  default     = false
}

variable "ai_pool_config" {
  description = "Configuration for AI/ML node pool with GPUs"
  type = object({
    machine_type   = string
    min_count      = number
    max_count      = number
    disk_size_gb   = number
    disk_type      = string
    gpu_type       = string
    gpu_count      = number
    spot           = bool
    node_locations = optional(list(string))
  })
  default = {
    machine_type   = "g2-standard-8" # NVIDIA L4 GPU
    min_count      = 0
    max_count      = 2
    disk_size_gb   = 250
    disk_type      = "pd-ssd"
    gpu_type       = "nvidia-l4"
    gpu_count      = 1
    spot           = true
    node_locations = null
  }
}

variable "cluster_labels" {
  description = "Resource labels to attach to cluster and node pools"
  type        = map(string)
  default = {
    environment = "dev"
    managed-by  = "terraform"
    platform    = "idp-core"
  }
}

