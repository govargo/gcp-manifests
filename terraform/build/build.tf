## ServiceAccount for Cloud Build
resource "google_service_account" "cloudbuild_service_account" {
  account_id = "cloud-build"
}

resource "google_project_iam_member" "act_as" {
  project = data.google_project.project.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"

  depends_on = [google_service_account.cloudbuild_service_account]
}

resource "google_project_iam_member" "logs_writer" {
  project = data.google_project.project.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"

  depends_on = [google_service_account.cloudbuild_service_account]
}

resource "google_project_iam_member" "artifact_writer" {
  project = data.google_project.project.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"

  depends_on = [google_service_account.cloudbuild_service_account]
}

data "google_iam_policy" "storage_admin" {
  binding {
    role = "roles/storage.admin"
    members = [
      "serviceAccount:${google_service_account.cloudbuild_service_account.email}",
    ]
  }

  depends_on = [google_service_account.cloudbuild_service_account]
}

resource "google_storage_bucket_iam_policy" "policy" {
  bucket      = data.google_project.project.project_id
  policy_data = data.google_iam_policy.storage_admin.policy_data
}

## Connect to repository
data "google_secret_manager_secret_version" "github_token_govargo_repository" {
  project = data.google_project.project.project_id
  secret  = "github_token_govargo_repository"
  version = "latest"
}

resource "google_secret_manager_secret_iam_member" "secret_accessor_cloudbuild_agent" {
  project   = data.google_project.project.project_id
  secret_id = data.google_secret_manager_secret_version.github_token_govargo_repository.secret
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

resource "google_cloudbuildv2_connection" "little_quest_repository" {
  project  = data.google_project.project.project_id
  location = var.region
  name     = "little-quest-repository"

  github_config {
    app_installation_id = "31531435"
    authorizer_credential {
      oauth_token_secret_version = data.google_secret_manager_secret_version.github_token_govargo_repository.id
    }
  }
  depends_on = [google_secret_manager_secret_iam_member.secret_accessor_cloudbuild_agent]
}

resource "google_cloudbuildv2_repository" "little_quest_server" {
  project           = data.google_project.project.project_id
  location          = var.region
  name              = "little-quest-server"
  parent_connection = google_cloudbuildv2_connection.little_quest_repository.name
  remote_uri        = "https://github.com/govargo/little-quest-server.git"

  depends_on = [google_cloudbuildv2_connection.little_quest_repository]
}

resource "google_cloudbuildv2_repository" "little_quest_realtime" {
  project           = data.google_project.project.project_id
  location          = var.region
  name              = "little-quest-realtime"
  parent_connection = google_cloudbuildv2_connection.little_quest_repository.name
  remote_uri        = "https://github.com/govargo/little-quest-realtime.git"

  depends_on = [google_cloudbuildv2_connection.little_quest_repository]
}

resource "google_cloudbuildv2_repository" "gcp_manifests" {
  project           = data.google_project.project.project_id
  location          = var.region
  name              = "gcp-manifests"
  parent_connection = google_cloudbuildv2_connection.little_quest_repository.name
  remote_uri        = "https://github.com/govargo/gcp-manifests.git"

  depends_on = [google_cloudbuildv2_connection.little_quest_repository]
}

## Cloud Build Trriger
resource "google_cloudbuild_trigger" "little_quest_server_build_trigger" {
  project         = data.google_project.project.project_id
  name            = "little-quest-server-build-trigger"
  location        = var.region
  filename        = "cloudbuild.yaml"
  service_account = google_service_account.cloudbuild_service_account.id

  repository_event_config {
    repository = google_cloudbuildv2_repository.little_quest_server.id
    push {
      branch = "(main|renovate/.*)"
    }
  }

  substitutions = {
    "_BUCKET_NAME" = data.google_project.project.project_id
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  depends_on = [google_service_account.cloudbuild_service_account, google_cloudbuildv2_repository.little_quest_server]
}

resource "google_cloudbuild_trigger" "little_quest_server_helm_chart_build_trigger" {
  project         = data.google_project.project.project_id
  name            = "little-quest-server-helm-chart-build-trigger"
  location        = var.region
  filename        = "k8s/helm/little-quest-server/cloudbuild.yaml"
  service_account = google_service_account.cloudbuild_service_account.id

  repository_event_config {
    repository = google_cloudbuildv2_repository.gcp_manifests.id
    push {
      tag = "^little-quest-server-[0-9].[0-9].[0-9]+$"
    }
  }

  substitutions = {
    "_BUCKET_NAME" = data.google_project.project.project_id
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  depends_on = [google_service_account.cloudbuild_service_account, google_cloudbuildv2_repository.gcp_manifests]
}

resource "google_cloudbuild_trigger" "multi_cluster_gateway_helm_chart_build_trigger" {
  project         = data.google_project.project.project_id
  name            = "multi-cluster-gateway-helm-chart-build-trigger"
  location        = var.region
  filename        = "k8s/helm/multi-cluster-gateway/cloudbuild.yaml"
  service_account = google_service_account.cloudbuild_service_account.id

  repository_event_config {
    repository = google_cloudbuildv2_repository.gcp_manifests.id
    push {
      tag = "^multi-cluster-gateway-[0-9].[0-9].[0-9]+$"
    }
  }

  substitutions = {
    "_BUCKET_NAME" = data.google_project.project.project_id
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  depends_on = [google_service_account.cloudbuild_service_account, google_cloudbuildv2_repository.gcp_manifests]
}

resource "google_cloudbuild_trigger" "little_quest_realtime_build_trigger" {
  project         = data.google_project.project.project_id
  name            = "little-quest-realtime-build-trigger"
  location        = var.region
  filename        = "cloudbuild.yaml"
  service_account = google_service_account.cloudbuild_service_account.id

  repository_event_config {
    repository = google_cloudbuildv2_repository.little_quest_realtime.id
    push {
      branch = "(main|renovate/.*)"
    }
  }

  substitutions = {
    "_BUCKET_NAME" = data.google_project.project.project_id
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  depends_on = [google_service_account.cloudbuild_service_account, google_cloudbuildv2_repository.little_quest_realtime]
}

resource "google_cloudbuild_trigger" "little_quest_realtime_helm_chart_build_trigger" {
  project         = data.google_project.project.project_id
  name            = "little-quest-realtime-helm-chart-build-trigger"
  location        = var.region
  filename        = "k8s/helm/little-quest-realtime/cloudbuild.yaml"
  service_account = google_service_account.cloudbuild_service_account.id

  repository_event_config {
    repository = google_cloudbuildv2_repository.gcp_manifests.id
    push {
      tag = "^little-quest-realtime-[0-9].[0-9].[0-9]+$"
    }
  }

  substitutions = {
    "_BUCKET_NAME" = data.google_project.project.project_id
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  depends_on = [google_service_account.cloudbuild_service_account, google_cloudbuildv2_repository.gcp_manifests]
}

