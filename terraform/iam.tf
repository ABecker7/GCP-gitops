# Service accounts for GKE Nodes

resource "google_service_account" "gke_nodes" {
  account_id   = "gke-node-sa-${random_id.cluster_suffix.hex}"
  display_name = "GKE Node Service Account"
  description  = "Service account for GKE nodes with minimal required permissions"
}

# IAM roles for node service account
resource "google_project_iam_member" "gke_nodes_log_write" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

