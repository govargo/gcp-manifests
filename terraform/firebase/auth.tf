resource "google_identity_platform_config" "default" {
  project = data.google_project.project.project_id

  autodelete_anonymous_users = true
  sign_in {
    allow_duplicate_emails = true

    anonymous {
      enabled = true
    }
  }

  monitoring {
    request_logging {
      enabled = false
    }
  }
}
