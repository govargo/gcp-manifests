## IAP Setting
data "google_compute_backend_service" "argocd_backend_service" {
  name = "k8s1-9c978f4e-argocd-argocd-server-80-a640d488"
}

resource "google_iap_web_backend_service_iam_binding" "argocd_iap_iam_binding" {
  project             = data.google_project.project.project_id
  web_backend_service = data.google_compute_backend_service.argocd_backend_service.name
  role                = "roles/iap.httpsResourceAccessor"
  members = [
    "user:admin@kentaiso.altostrat.com",
  ]
}

## Secret
resource "google_secret_manager_secret" "argocd_client_id" {
  project   = data.google_project.project.project_id
  secret_id = "argocd_client_id"

  labels = {
    role = "argocd_client_id"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "argocd_client_secret" {
  project   = data.google_project.project.project_id
  secret_id = "argocd_client_secret"

  labels = {
    role = "argocd_client_secret"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "argocd_notification_webhook_url" {
  project   = data.google_project.project.project_id
  secret_id = "argocd_notification_webhook_url"

  labels = {
    role = "argocd_notification_webhook_url"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

