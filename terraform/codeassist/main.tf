data "google_project" "project" {
}

resource "null_resource" "get_current_google_account" {
  provisioner "local-exec" {
    command = "gcloud config get core/account > /tmp/gcloud_account.txt"
  }
}

## Developer Connect
resource "google_developer_connect_connection" "developer_connection_github" {
  provider      = google-beta
  location      = "asia-southeast1"
  connection_id = "github-little-quest"
  github_config {
    github_app = "DEVELOPER_CONNECT"
  }

  depends_on = [google_project_iam_member.devconnect-secret]
}

output "next_steps" {
  description = "Follow the action_uri if present to continue setup"
  value       = google_developer_connect_connection.developer_connection_github.installation_state
}

# Setup permissions. Only needed once per project
resource "google_project_service_identity" "devconnect-p4sa" {
  provider = google-beta
  service  = "developerconnect.googleapis.com"
}

resource "google_project_iam_member" "devconnect-secret" {
  provider = google-beta
  project  = data.google_project.project.id
  role     = "roles/secretmanager.admin"
  member   = google_project_service_identity.devconnect-p4sa.member

  depends_on = [google_project_service_identity.devconnect-p4sa]
}

## Repository Index
resource "google_gemini_code_repository_index" "little_quest_index" {
  location                 = "asia-southeast1"
  code_repository_index_id = "little-quest-index"
}

## Repository Groups
resource "google_gemini_repository_group" "little_quest_group" {
  provider              = google-beta
  location              = "asia-southeast1"
  code_repository_index = "little-quest-index"
  repository_group_id   = "little-quest-group"
  repositories {
    resource       = "projects/prd-little-quest/locations/asia-southeast1/connections/github-little-quest/gitRepositoryLinks/govargo-little-quest-server"
    branch_pattern = "main"
  }

  repositories {
    resource       = "projects/prd-little-quest/locations/asia-southeast1/connections/github-little-quest/gitRepositoryLinks/govargo-little-quest-realtime"
    branch_pattern = "main"
  }

  depends_on = [
    google_developer_connect_connection.developer_connection_github,
    google_gemini_code_repository_index.little_quest_index,
  ]
}

## IAM to Repository Groups
data "google_iam_policy" "admin" {
  provider = google-beta
  binding {
    role = "roles/cloudaicompanion.repositoryGroupsUser"
    members = [
      ## Add current google user account only
      "user:${trimspace(file("/tmp/gcloud_account.txt"))}",
    ]
  }

  depends_on = [null_resource.get_current_google_account]
}

resource "google_gemini_repository_group_iam_policy" "admin" {
  provider              = google-beta
  project               = "prd-little-quest"
  location              = "asia-southeast1"
  code_repository_index = "little-quest-index"
  repository_group_id   = "little-quest-group"
  policy_data           = data.google_iam_policy.admin.policy_data

  depends_on = [google_gemini_repository_group.little_quest_group]
}

