## ServiceAccount

# argocd-server
module "argocd_server_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.4.2"
  project_id = data.google_project.project.project_id

  names         = ["argocd-server"]
  display_name  = "ArgoCD Server ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/container.admin",
    "${data.google_project.project.project_id}=>roles/gkehub.gatewayEditor"
  ]
}

module "argocd_server_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.0.0"
  project = data.google_project.project.project_id

  service_accounts = [module.argocd_server_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[argocd/argocd-server]"
    ]
  }

  depends_on = [module.argocd_server_sa, kubernetes_service_account.misc0_argocd_server]
}

# argocd-application-controller
module "argocd_application_controller_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.4.2"
  project_id = data.google_project.project.project_id

  names         = ["argocd-application-controller"]
  display_name  = "ArgoCD Application Controller ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/container.admin",
    "${data.google_project.project.project_id}=>roles/gkehub.gatewayEditor"
  ]
}

module "argocd_application_controller_sa_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.0.0"
  project = data.google_project.project.project_id

  service_accounts = [module.argocd_application_controller_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[argocd/argocd-application-controller]"
    ]
  }

  depends_on = [module.argocd_server_sa, kubernetes_service_account.misc0_argocd_application_controller]
}

# argocd-dex-server
module "argocd_dex_server_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.4.2"
  project_id = data.google_project.project.project_id

  names        = ["argocd-dex-server"]
  display_name = "ArgoCD Dex Server ServiceAccount"
}

module "argocd_dex_server_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.0.0"
  project = data.google_project.project.project_id

  service_accounts = [module.argocd_dex_server_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[argocd/argocd-dex-server]"
    ]
  }

  depends_on = [module.argocd_dex_server_sa, kubernetes_service_account.misc0_argocd_dex_server]
}

module "argocd_dex_server_secret_accessor_binding" {
  source  = "terraform-google-modules/iam/google//modules/secret_manager_iam"
  version = "8.0.0"
  project = data.google_project.project.project_id

  secrets = ["argocd_client_id", "argocd_client_secret"]
  mode    = "authoritative"

  bindings = {
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:${module.argocd_dex_server_sa.service_account.email}"
    ]
  }

  depends_on = [module.argocd_dex_server_sa]
}

# argocd-repo-server
module "argocd_repo_server_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.4.2"
  project_id = data.google_project.project.project_id

  names         = ["argocd-repo-server"]
  display_name  = "ArgoCD Repo server ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/artifactregistry.reader"]
}

module "argocd_repo_server_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.0.0"
  project = data.google_project.project.project_id

  service_accounts = [module.argocd_repo_server_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[argocd/argocd-repo-server]"
    ]
  }

  depends_on = [module.argocd_repo_server_sa, kubernetes_service_account.misc0_argocd_repo_server]
}

# argocd-notification-controller
module "argocd_notifications_controller_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.4.2"
  project_id = data.google_project.project.project_id

  names        = ["argocd-notifications"]
  display_name = "ArgoCD Notifications Controller ServiceAccount"
}

module "argocd_notifications_controller_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.0.0"
  project = data.google_project.project.project_id

  service_accounts = [module.argocd_notifications_controller_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[argocd/argocd-notifications]"
    ]
  }

  depends_on = [module.argocd_notifications_controller_sa, kubernetes_service_account.misc0_argocd_argocd_notifications]
}

module "argocd_notifications_controller_secret_accessor_binding" {
  source  = "terraform-google-modules/iam/google//modules/secret_manager_iam"
  version = "8.0.0"
  project = data.google_project.project.project_id

  secrets = [google_secret_manager_secret.argocd_notification_webhook_url.secret_id]
  mode    = "authoritative"
  bindings = {
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:${module.argocd_notifications_controller_sa.email}"
    ]
  }
  depends_on = [
    module.argocd_notifications_controller_sa,
    google_secret_manager_secret.argocd_notification_webhook_url
  ]
}

# argocd-image-updater
module "argocd_image_updater_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.4.2"
  project_id = data.google_project.project.project_id

  names         = ["argocd-image-updater"]
  display_name  = "ArgoCD image updater ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/artifactregistry.reader"]
}

module "argocd_image_updater_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.0.0"
  project = data.google_project.project.project_id

  service_accounts = [module.argocd_image_updater_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[argocd/argocd-image-updater]"
    ]
  }
  depends_on = [module.argocd_image_updater_sa, kubernetes_service_account.misc0_argocd_argocd_image_updater]
}

# google managed prometheus(GMP) rule-evaluator
resource "google_project_iam_custom_role" "gmp_rule_evaluator_role" {
  role_id     = "ruleevaluator"
  title       = "GMP Rule Evaluator"
  description = "GMP Rule Evaluator Monitoring role"
  permissions = ["monitoring.timeSeries.create", "monitoring.timeSeries.list"]
  stage       = "GA"
}

# google managed prometheus(GMP) collector
# Kubernetes deployment rule-evaluator uses collector service account
module "gmp_collector_sa" {
  source       = "terraform-google-modules/service-accounts/google"
  version      = "4.4.2"
  project_id   = data.google_project.project.project_id
  names        = ["collector"]
  display_name = "Google Managed Prometheus Collector ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/monitoring.metricWriter",
    "${data.google_project.project.project_id}=>projects/${data.google_project.project.project_id}/roles/${google_project_iam_custom_role.gmp_rule_evaluator_role.role_id}",
  ]
  depends_on = [google_project_iam_custom_role.gmp_rule_evaluator_role]
}

module "gmp_collector_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.0.0"
  project = data.google_project.project.project_id

  service_accounts = [module.gmp_collector_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[gmp-system/collector]"
    ]
  }
  depends_on = [module.gmp_collector_sa, kubernetes_service_account.misc0_gmp_collector]
}
