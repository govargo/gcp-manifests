data "google_project" "project" {
}

## Firebase
resource "google_firebase_project" "little_quest" {
  provider = google-beta
  project  = data.google_project.project.project_id
}
