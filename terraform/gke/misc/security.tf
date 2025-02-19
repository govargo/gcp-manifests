## IAP Setting
## Rename if you create argocd via K8s Ingress
data "google_compute_backend_service" "argocd_backend_service" {
  name = "k8s1-9c978f4e-argocd-argocd-server-80-a640d488"
}

resource "null_resource" "get_current_google_account" {
  provisioner "local-exec" {
    command = "gcloud config get core/account > /tmp/gcloud_account.txt"
  }
}

resource "google_iap_web_backend_service_iam_binding" "argocd_iap_iam_binding" {
  project             = data.google_project.project.project_id
  web_backend_service = data.google_compute_backend_service.argocd_backend_service.name
  role                = "roles/iap.httpsResourceAccessor"
  members = [
    "user:${trimspace(file("/tmp/gcloud_account.txt"))}",
  ]

  depends_on = [null_resource.get_current_google_account]
}

data "google_secret_manager_secret_version" "argocd_client_id" {
  secret = "argocd_client_id"
}

## IAP Client
## You must create OAuth Client Credential via Cloud Console, because terraform resource creation has limitations
import {
  id = "projects/${data.google_project.project.number}/brands/${data.google_project.project.number}/identityAwareProxyClients/${data.google_secret_manager_secret_version.argocd_client_id.secret_data}"
  to = google_iap_client.argocd_iap_oauth_client
}

resource "google_iap_client" "argocd_iap_oauth_client" {
  display_name = "ArgoCD"
  brand        = "projects/${data.google_project.project.number}/brands/${data.google_project.project.number}"
}

## Secret
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

