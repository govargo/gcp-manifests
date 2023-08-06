## Cloud Build
resource "google_cloudbuild_trigger" "little_server_build_trigger" {
  project  = data.google_project.project.project_id
  name     = "little-server-build-trigger"
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

resource "google_cloudbuild_trigger" "little_quest_helm_chart_build_trigger" {
  project  = data.google_project.project.project_id
  name     = "little-quest-helm-chart-build-trigger"
  location = var.region
  filename = "k8s/helm/little-quest/cloudbuild.yaml"

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
