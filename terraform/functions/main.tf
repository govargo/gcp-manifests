data "google_project" "project" {
}

## Secret
resource "google_secret_manager_secret" "gke_cluster_upgrade_notifier_url" {
  project   = data.google_project.project.project_id
  secret_id = "gke_cluster_upgrade_notifier_url"

  labels = {
    role = "gke_cluster_upgrade_notifier_url"
  }

  lifecycle {
    prevent_destroy = true
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "alertmanager_to_google_chat_url" {
  project   = data.google_project.project.project_id
  secret_id = "alertmanager_to_google_chat_url"

  labels = {
    role = "alertmanager_to_google_chat_url"
  }

  lifecycle {
    prevent_destroy = true
  }

  replication {
    auto {}
  }
}

## Service Account
module "gke_cluster_upgrade_notifier_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.5.3"
  project_id = data.google_project.project.project_id

  names         = ["gke-cluster-upgrade-notifier"]
  display_name  = "GKE Cluster Upgrade Notifier ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/run.invoker"]
}

module "gke_cluster_upgrade_notifier_secret_accessor_binding" {
  source  = "terraform-google-modules/iam/google//modules/secret_manager_iam"
  version = "8.1.0"
  project = data.google_project.project.project_id

  secrets = [google_secret_manager_secret.gke_cluster_upgrade_notifier_url.secret_id]
  mode    = "authoritative"
  bindings = {
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:${module.gke_cluster_upgrade_notifier_sa.email}"
    ]
  }
  depends_on = [module.gke_cluster_upgrade_notifier_sa, google_secret_manager_secret.gke_cluster_upgrade_notifier_url]
}

module "alertmanager_to_google_chat_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.5.3"
  project_id = data.google_project.project.project_id

  names         = ["alertmanager-to-google-chat"]
  display_name  = "Alertmanager to Google Chat ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/run.invoker"]
}

module "alertmanager_to_google_chat_url_secret_accessor_binding" {
  source  = "terraform-google-modules/iam/google//modules/secret_manager_iam"
  version = "8.1.0"
  project = data.google_project.project.project_id

  secrets = [google_secret_manager_secret.alertmanager_to_google_chat_url.secret_id]
  mode    = "authoritative"
  bindings = {
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:${module.alertmanager_to_google_chat_sa.email}"
    ]
  }
  depends_on = [module.alertmanager_to_google_chat_sa, google_secret_manager_secret.alertmanager_to_google_chat_url]
}

module "alertmanager_to_google_chat_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.1.0"
  project = data.google_project.project.project_id

  service_accounts = [module.alertmanager_to_google_chat_sa.email]
  mode             = "authoritative"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[gmp-system/default]"
    ]
  }
  depends_on = [module.alertmanager_to_google_chat_sa]
}

## Eventarc
resource "google_eventarc_google_channel_config" "google_config" {
  project  = data.google_project.project.project_id
  location = var.region
  name     = "projects/${data.google_project.project.project_id}/locations/${var.region}/googleChannelConfig"
}

## Object Upload to Cloud Storage
resource "google_storage_bucket_object" "gke_cluster_upgrade_notifier_source" {
  name   = "gke-cluster-upgrade-notifier/function-source.zip"
  source = "files/gke-cluster-upgrade-notifier/function-source.zip"
  bucket = data.google_project.project.project_id
}

resource "google_storage_bucket_object" "alertmanager_to_google_chat_source" {
  name   = "alertmanager-to-google-chat/function-source.zip"
  source = "files/alertmanager-to-google-chat/function-source.zip"
  bucket = data.google_project.project.project_id
}

## Cloud Functions v2
resource "google_cloudfunctions2_function" "gke_cluster_upgrade_notifier" {
  project     = data.google_project.project.project_id
  name        = "gke-cluster-upgrade-notifier"
  location    = var.region
  description = "GKE Cluster Upgrade Notifier to Google Chat"

  labels = {
    "env"             = var.env
    "case"            = "gke-cluster-upgrade-notifier"
    "deployment-tool" = "console-cloud"
  }

  build_config {
    runtime           = "nodejs20"
    entry_point       = "sendNotificationForGKEClussterUpgradeToChat"
    docker_repository = "projects/${data.google_project.project.project_id}/locations/${var.region}/repositories/cloud-run-source-deploy"
    source {
      storage_source {
        bucket = data.google_project.project.project_id
        object = "gke-cluster-upgrade-notifier/function-source.zip"
      }
    }
  }

  event_trigger {
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = "projects/${data.google_project.project.project_id}/topics/gke-cluster-upgrade-notification"
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    service_account_email = module.gke_cluster_upgrade_notifier_sa.email
    trigger_region        = var.region
  }

  service_config {
    min_instance_count               = 0
    max_instance_count               = 1
    available_memory                 = "256Mi"
    timeout_seconds                  = 60
    ingress_settings                 = "ALLOW_INTERNAL_ONLY"
    max_instance_request_concurrency = 1
    service_account_email            = module.gke_cluster_upgrade_notifier_sa.email

    secret_environment_variables {
      project_id = data.google_project.project.project_id
      key        = "WEBHOOK_URL"
      secret     = google_secret_manager_secret.gke_cluster_upgrade_notifier_url.secret_id
      version    = "latest"
    }
  }

  #lifecycle {
  #  ignore_changes = [
  #    build_config[0].source[0].storage_source[0].generation
  #  ]
  #}

  depends_on = [
    module.gke_cluster_upgrade_notifier_sa,
    google_secret_manager_secret.gke_cluster_upgrade_notifier_url,
    google_storage_bucket_object.gke_cluster_upgrade_notifier_source,
    google_eventarc_google_channel_config.google_config
  ]
}

resource "google_cloudfunctions2_function" "alertmanager_to_google_chat" {
  project     = data.google_project.project.project_id
  name        = "alertmanager-to-google-chat"
  location    = var.region
  description = "Alertmanager Notifier to Google Chat"

  labels = {
    "env"             = var.env
    "case"            = "alertmanager-to-google-chat"
    "deployment-tool" = "console-cloud"
  }

  build_config {
    runtime           = "nodejs20"
    entry_point       = "sendNotificationForAlertmanagerToChat"
    docker_repository = "projects/${data.google_project.project.project_id}/locations/${var.region}/repositories/cloud-run-source-deploy"
    source {
      storage_source {
        bucket = data.google_project.project.project_id
        object = "alertmanager-to-google-chat/function-source.zip"
      }
    }
  }

  service_config {
    min_instance_count               = 0
    max_instance_count               = 2
    available_cpu                    = 1
    available_memory                 = "256Mi"
    timeout_seconds                  = 120
    ingress_settings                 = "ALLOW_INTERNAL_ONLY"
    max_instance_request_concurrency = 10
    service_account_email            = module.alertmanager_to_google_chat_sa.email
    secret_environment_variables {
      project_id = data.google_project.project.project_id
      key        = "WEBHOOK_URL"
      secret     = google_secret_manager_secret.alertmanager_to_google_chat_url.secret_id
      version    = "latest"
    }
  }

  #lifecycle {
  #  ignore_changes = [
  #    build_config[0].source[0].storage_source[0].generation
  #  ]
  #}

  depends_on = [
    module.alertmanager_to_google_chat_sa,
    google_secret_manager_secret.alertmanager_to_google_chat_url,
    google_storage_bucket_object.alertmanager_to_google_chat_source
  ]
}

