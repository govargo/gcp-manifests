data "google_project" "project" {
}

resource "google_secret_manager_secret" "github_token_dataform" {
  project   = data.google_project.project.project_id
  secret_id = "github_token_dataform"

  labels = {
    role = "github_token_dataform"
  }

  lifecycle {
    prevent_destroy = true
  }

  replication {
    auto {}
  }
}

data "google_secret_manager_secret_version" "github_token_dataform" {
  secret = "github_token_dataform"
}

resource "google_secret_manager_secret_iam_member" "secretemanager_accessor" {
  project   = data.google_project.project.project_id
  secret_id = google_secret_manager_secret.github_token_dataform.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

resource "google_dataform_repository" "little_dataform_repository" {
  provider = google-beta
  project  = data.google_project.project.project_id
  name     = "${var.env}-little-quest-dataform"
  region   = var.region

  git_remote_settings {
    url                                 = "https://github.com/govargo/little-quest-dataform.git"
    default_branch                      = "main"
    authentication_token_secret_version = data.google_secret_manager_secret_version.github_token_dataform.id
  }
}

resource "google_project_iam_member" "bigquery_role" {
  project = data.google_project.project.project_id
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
  ])
  role   = each.key
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}
