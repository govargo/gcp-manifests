## Cloud Build
resource "google_cloudbuild_trigger" "little_quest_server_build_trigger" {
  project  = data.google_project.project.project_id
  name     = "little-quest-server-build-trigger"
  location = var.region
  filename = "cloudbuild.yaml"

  github {
    owner = "govargo"
    name  = "little-quest-server"
    push {
      branch = "^main$"
    }
  }

  substitutions = {
    "_BUCKET_NAME" = data.google_project.project.project_id
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
}

resource "google_cloudbuild_trigger" "little_quest_server_helm_chart_build_trigger" {
  project  = data.google_project.project.project_id
  name     = "little-quest-server-helm-chart-build-trigger"
  location = var.region
  filename = "k8s/helm/little-quest-server/cloudbuild.yaml"

  github {
    owner = "govargo"
    name  = "gcp-manifests"
    push {
      tag = "^[0-9].[0-9].[0-9]$"
    }
  }

  substitutions = {
    "_BUCKET_NAME" = data.google_project.project.project_id
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
}

resource "google_cloudbuild_trigger" "little_quest_realtime_build_trigger" {
  project  = data.google_project.project.project_id
  name     = "little-quest-realtime-build-trigger"
  location = var.region
  filename = "cloudbuild.yaml"

  github {
    owner = "govargo"
    name  = "little-quest-realtime"
    push {
      branch = "^main$"
    }
  }

  substitutions = {
    "_BUCKET_NAME" = data.google_project.project.project_id
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
}
