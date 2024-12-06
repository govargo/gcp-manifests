## IAP Setting
#data "google_compute_backend_service" "argocd_backend_service" {
#  name = "k8s1-f8f020c8-argocd-argocd-server-80-2a46cd0c"
#}

#resource "google_iap_web_backend_service_iam_binding" "argocd_iap_iam_binding" {
#  project             = data.google_project.project.project_id
#  web_backend_service = data.google_compute_backend_service.argocd_backend_service.name
#  role                = "roles/iap.httpsResourceAccessor"
#  members = [
#    "user:admin@kentaiso.altostrat.com",
#  ]
#}

## OAuth Client
resource "google_iap_client" "argocd_iap_oauth_client" {
  display_name = "ArgoCD"
  brand        = "projects/${data.google_project.project.number}/brands/${data.google_project.project.number}"
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

  depends_on = [google_iap_client.argocd_iap_oauth_client]
}

resource "google_secret_manager_secret_version" "argocd_client_id" {
  secret = google_secret_manager_secret.argocd_client_id.id

  secret_data = google_iap_client.argocd_iap_oauth_client.client_id

  depends_on = [google_secret_manager_secret.argocd_client_id]
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

  depends_on = [google_iap_client.argocd_iap_oauth_client]
}

resource "google_secret_manager_secret_version" "argocd_client_secret" {
  secret = google_secret_manager_secret.argocd_client_secret.id

  secret_data = google_iap_client.argocd_iap_oauth_client.secret

  depends_on = [google_iap_client.argocd_iap_oauth_client, google_secret_manager_secret.argocd_client_secret]
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
