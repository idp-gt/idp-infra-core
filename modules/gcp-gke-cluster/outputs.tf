output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "endpoint" {
  description = "The IP address of the GKE cluster Kubernetes master"
  value       = google_container_cluster.primary.endpoint
}

output "ca_certificate" {
  description = "The base64 encoded public certificate that is the root CA of the cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "service_account_email" {
  description = "The email of the dedicated service account created for GKE nodes"
  value       = google_service_account.gke_sa.email
}

output "get_credentials_command" {
  description = "gcloud command to configure kubectl credentials for this cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id}"
}

