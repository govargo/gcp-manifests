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
    automatic = true
  }
}

## Service Account
module "gke_cluster_upgrade_notifier_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.1.1"
  project_id = data.google_project.project.project_id

  names         = ["gke-cluster-upgrade-notifier"]
  display_name  = "GKE Cluster Upgrade Notifier ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/run.invoker"]
}

module "gke_cluster_upgrade_notifier_secret_accessor_binding" {
  source  = "terraform-google-modules/iam/google//modules/secret_manager_iam"
  version = "7.6.0"
  project = data.google_project.project.project_id

  secrets = [google_secret_manager_secret.gke_cluster_upgrade_notifier_url.secret_id]
  mode    = "additive"
  bindings = {
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:${module.gke_cluster_upgrade_notifier_sa.email}"
    ]
  }
  depends_on = [module.gke_cluster_upgrade_notifier_sa, google_secret_manager_secret.gke_cluster_upgrade_notifier_url]
}

## Eventarc
resource "google_eventarc_google_channel_config" "google_config" {
  project  = data.google_project.project.project_id
  location = var.region
  name     = "projects/${data.google_project.project.project_id}/locations/${var.region}/googleChannelConfig"
}

resource "google_eventarc_trigger" "gke_cluster_upgrade_notifier" {
  project  = data.google_project.project.project_id
  name     = "gke-cluster-upgrade-notifier-446780"
  location = var.region

  labels = {
    "goog-managed-by" = "cloudfunctions"
  }

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  service_account = module.gke_cluster_upgrade_notifier_sa.email
  destination {
    cloud_function = "projects/${data.google_project.project.project_id}/locations/${var.region}/functions/gke-cluster-upgrade-notifier"
  }
}

## Cloud Functions
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
    runtime     = "nodejs20"
    entry_point = "sendNotificationForGKEClussterUpgradeToChat"
    source {
      storage_source {
        bucket = "gcf-v2-sources-${data.google_project.project.number}-${var.region}"
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
    ingress_settings                 = "ALLOW_ALL"
    max_instance_request_concurrency = 1

    secret_environment_variables {
      project_id = data.google_project.project.project_id
      key        = "WEBHOOK_URL"
      secret     = google_secret_manager_secret.gke_cluster_upgrade_notifier_url.secret_id
      version    = "latest"
    }
  }

  lifecycle {
    ignore_changes = [
      build_config[0].source[0].storage_source[0].generation
    ]
  }

  depends_on = [
    module.gke_cluster_upgrade_notifier_sa,
    google_secret_manager_secret.gke_cluster_upgrade_notifier_url,
    google_eventarc_trigger.gke_cluster_upgrade_notifier
  ]
}
