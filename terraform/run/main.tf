data "google_project" "project" {
}

## Cloud Storage
resource "google_storage_bucket_object" "cloud_build_notifier_yaml" {
  name   = "cloud_build_notifier.yaml"
  source = "file/cloud_build_notifier.yaml"
  bucket = data.google_project.project.project_id
}

## Secret
resource "google_secret_manager_secret" "cloud_build_notifier_url" {
  project   = data.google_project.project.project_id
  secret_id = "cloud_build_notifier_url"

  labels = {
    role = "cloud_build_notifier_url"
  }

  lifecycle {
    prevent_destroy = true
  }

  replication {
    auto {}
  }
}

## Service Account
module "cloud_build_notifier_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.3.0"
  project_id = data.google_project.project.project_id

  names         = ["cloud-build-notifier"]
  display_name  = "Cloud Build Notifier ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/storage.objectViewer"]
}

module "cloud_build_notifier_secret_accessor_binding" {
  source  = "terraform-google-modules/iam/google//modules/secret_manager_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  secrets = [google_secret_manager_secret.cloud_build_notifier_url.secret_id]
  mode    = "additive"
  bindings = {
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:${module.cloud_build_notifier_sa.email}"
    ]
  }
  depends_on = [module.cloud_build_notifier_sa, google_secret_manager_secret.cloud_build_notifier_url]
}

module "cloud_run_pubsub_invoker_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.3.0"
  project_id = data.google_project.project.project_id

  names        = ["cloud-run-pubsub-invoker"]
  display_name = "Cloud Run Pub/Sub Invoker"
}


resource "google_project_iam_member" "cloud_run_pubsub_invoker" {
  project    = data.google_project.project.project_id
  role       = "roles/run.invoker"
  member     = "serviceAccount:${module.cloud_run_pubsub_invoker_sa.email}"
  depends_on = [module.cloud_run_pubsub_invoker_sa]
}

## Cloud Run
resource "google_cloud_run_v2_service" "cloud_build_notifier" {
  project  = data.google_project.project.project_id
  name     = "cloud-build-notifier"
  location = var.region

  ingress = "INGRESS_TRAFFIC_ALL"
  template {
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    scaling {
      max_instance_count = 1
    }
    containers {
      image = "us-east1-docker.pkg.dev/gcb-release/cloud-build-notifiers/googlechat:googlechat-0.2.4"
      env {
        name  = "CONFIG_PATH"
        value = "gs://${data.google_project.project.project_id}/cloud_build_notifier.yaml"
      }
      env {
        name  = "PROJECT_ID"
        value = data.google_project.project.project_id
      }
    }
    service_account = module.cloud_build_notifier_sa.email
  }
  timeouts {}
}

## Cloud Pub/Sub
module "cloud_builds_notifier" {
  source     = "terraform-google-modules/pubsub/google"
  version    = "6.0.0"
  project_id = data.google_project.project.project_id

  topic                            = "cloud-builds"
  create_topic                     = true
  grant_token_creator              = true
  topic_message_retention_duration = "604800s"
  topic_labels = {
    env  = "production",
    case = "cloud-builds"
  }

  push_subscriptions = [
    {
      name                       = "cloud-build-notifier-subscription"
      ack_deadline_seconds       = 20
      push_endpoint              = google_cloud_run_v2_service.cloud_build_notifier.uri
      x-goog-version             = "v1"
      oidc_service_account_email = "${module.cloud_run_pubsub_invoker_sa.email}"
      expiration_policy          = ""
      dead_letter_topic          = "projects/${data.google_project.project.project_id}/topics/${var.env}-dead-letter"
      max_delivery_attempts      = 5
      maximum_backoff            = "600s"
      minimum_backoff            = "300s"
    }
  ]

  depends_on = [google_cloud_run_v2_service.cloud_build_notifier]
}
