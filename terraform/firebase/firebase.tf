data "google_project" "project" {
}

## Firebase
resource "google_firebase_project" "little_quest" {
  provider = google-beta
  project  = data.google_project.project.project_id
}

resource "google_firebase_project_location" "fireabase_location" {
  provider = google-beta
  project  = google_firebase_project.little_quest.project

  location_id = var.region

  depends_on = [google_firebase_project.little_quest]
}
