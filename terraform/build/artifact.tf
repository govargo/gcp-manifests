data "google_project" "project" {
}

## Artifact Registry
resource "google_artifact_registry_repository" "docker_repository" {
  project = data.google_project.project.project_id

  location      = var.region
  repository_id = "little-quest"
  description   = "Docker repository"
  format        = "DOCKER"
}
