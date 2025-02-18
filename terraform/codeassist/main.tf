data "google_project" "project" {
}

# resource "google_developer_connect_connection" "developer_connection_github" {
#  provider      = google-beta
#  location      = "asia-southeast1"
#  connection_id = "github-little-quest"
#  github_config {
#    github_app = "DEVELOPER_CONNECT"
#  }

#  depends_on = [google_project_iam_member.devconnect-secret]
#}

#output "next_steps" {
#  description = "Follow the action_uri if present to continue setup"
#  value       = google_developer_connect_connection.developer_connection_github.installation_state
#}

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
}
