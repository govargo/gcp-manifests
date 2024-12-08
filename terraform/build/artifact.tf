data "google_project" "project" {
}

## Artifact Registry
resource "google_artifact_registry_repository" "docker_repository_little_quest" {
  project = data.google_project.project.project_id

  location      = var.region
  repository_id = "little-quest"
  description   = "Docker repository for Little Quest"
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

resource "google_artifact_registry_repository" "docker_repository_multi_cluster_gateway" {
  project = data.google_project.project.project_id

  location      = var.region
  repository_id = "multi-cluster-gateway"
  description   = "Docker repository for Multi Cluster Gateway chart"
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

resource "google_artifact_registry_repository" "docker_repository_open_match" {
  project = data.google_project.project.project_id

  location      = var.region
  repository_id = "open-match"
  description   = "Docker repository for Open Match"
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
      keep_count            = 2
    }
  }
}

