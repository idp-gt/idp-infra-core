output "control_plane_ips" {
  description = "List of internal and external IP addresses of control plane instances"
  value = [
    for instance in google_compute_instance.control_plane : {
      name        = instance.name
      internal_ip = instance.network_interface[0].network_ip
      external_ip = try(instance.network_interface[0].access_config[0].nat_ip, null)
    }
  ]
}

output "worker_ips" {
  description = "List of internal and external IP addresses of worker instances"
  value = [
    for instance in google_compute_instance.workers : {
      name        = instance.name
      internal_ip = instance.network_interface[0].network_ip
      external_ip = try(instance.network_interface[0].access_config[0].nat_ip, null)
    }
  ]
}

output "ansible_inventory_path" {
  description = "Location of rendered Ansible inventory file"
  value       = var.generate_inventory_file ? var.inventory_output_path : null
}

