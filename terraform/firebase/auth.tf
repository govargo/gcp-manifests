resource "google_identity_platform_config" "default" {
  project = data.google_project.project.project_id

  autodelete_anonymous_users = true
  sign_in {
    allow_duplicate_emails = true

    anonymous {
      enabled = true
    }
  }

  quota {
    sign_up_quota_config {
      quota          = 1000
      quota_duration = "604800s"
      start_time     = "2024-12-03T08:00:00Z"
    }
  }

  monitoring {
    request_logging {
      enabled = false
    }
  }
}
