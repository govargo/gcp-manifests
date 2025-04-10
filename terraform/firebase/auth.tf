resource "google_identity_platform_config" "default" {
  project = data.google_project.project.project_id

  autodelete_anonymous_users = true
  sign_in {
    allow_duplicate_emails = true

    anonymous {
      enabled = true
    }

    email {
      enabled           = false
      password_required = false
    }

    phone_number {
      enabled            = false
      test_phone_numbers = {}
    }

  }

  quota {
    sign_up_quota_config {
      quota          = 1000
      quota_duration = "604800s"
      start_time     = "2025-02-07T08:06:00Z"
    }
  }

  monitoring {
    request_logging {
      enabled = false
    }
  }
}
