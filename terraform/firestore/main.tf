data "google_project" "project" {
}

resource "google_firestore_database" "default" {
  project = data.google_project.project.project_id

  name                        = "(default)"
  location_id                 = var.region
  type                        = "FIRESTORE_NATIVE"
  concurrency_mode            = "OPTIMISTIC"
  app_engine_integration_mode = "DISABLED"
}
