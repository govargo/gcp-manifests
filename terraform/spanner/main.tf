resource "google_spanner_instance" "prod_instance" {
  project = var.gcp_project_id

  name             = "${var.env}-spanner"
  config           = "regional-asia-northeast1"
  display_name     = "Spanner Production Instance"
  processing_units = 100
  labels = {
    "env" = "production"
  }
  force_destroy = true
}

resource "google_spanner_database" "usesr_database" {
  project = var.gcp_project_id

  instance                 = google_spanner_instance.prod_instance.name
  name                     = "user_data"
  version_retention_period = "1h"
  ddl                      = []
  database_dialect         = var.database_dialect
  deletion_protection      = false

  depends_on = [google_spanner_instance.prod_instance]
}
