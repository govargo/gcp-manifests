data "google_project" "project" {
}

data "google_secret_manager_secret" "github_token_dataform" {
  secret_id = "github_token_dataform"
}

data "google_secret_manager_secret_version" "github_token_dataform" {
  secret = "github_token_dataform"
}

resource "google_secret_manager_secret_iam_member" "secretemanager_accessor" {
  project   = data.google_project.project.project_id
  secret_id = data.google_secret_manager_secret.github_token_dataform.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

# https://docs.cloud.google.com/bigquery/docs/release-notes#January_19_2026
module "custom_dataform_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.7.0"
  project_id = data.google_project.project.project_id

  names        = ["custom-dataform"]
  display_name = "Custom Dataform ServiceAccount for strict-service-act"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/bigquery.dataEditor",
    "${data.google_project.project.project_id}=>roles/bigquery.jobUser",
    "${data.google_project.project.project_id}=>roles/iam.serviceAccountTokenCreator",
    "${data.google_project.project.project_id}=>roles/iam.serviceAccountUser"
  ]
}

# actAs enforcement changed by manually
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

  service_account = module.custom_dataform_sa.email

  depends_on = [module.custom_dataform_sa]
}

# https://docs.cloud.google.com/bigquery/docs/release-notes#January_19_2026
resource "google_project_iam_member" "bigquery_role" {
  project = data.google_project.project.project_id
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/iam.serviceAccountUser"
  ])
  role   = each.key
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}
