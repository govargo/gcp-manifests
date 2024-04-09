data "google_project" "project" {
}

## Artifact Registry
resource "google_artifact_registry_repository" "docker_repository" {
  project = data.google_project.project.project_id

  location      = var.region
  repository_id = "little-quest"
  description   = "Docker repository"
  format        = "DOCKER"

  cleanup_policies {
    id     = "delete-prerelease"
    action = "DELETE"
    condition {
      tag_state             = "TAGGED"
      tag_prefixes          = []
      version_name_prefixes = []
      older_than            = "2678400s"
    }
  }

  cleanup_policies {
    id     = "keep-tagged-release"
    action = "KEEP"
    condition {
      tag_state             = "TAGGED"
      tag_prefixes          = []
      version_name_prefixes = []
      newer_than            = "2592000s"
    }
  }

  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      package_name_prefixes = []
      keep_count            = 5
    }
  }
}
