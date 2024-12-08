data "google_project" "project" {
}

resource "time_sleep" "wait_150_seconds" {
  depends_on = [
    google_project_service.service
  ]

  create_duration = "150s"
}

## Service APIs
locals {
  services = toset([
    "cloudbilling.googleapis.com",
    "artifactregistry.googleapis.com",
    "autoscaling.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "cloudapis.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containersecurity.googleapis.com",
    "containerscanning.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "multiclusterservicediscovery.googleapis.com",
    "multiclusteringress.googleapis.com",
    "mesh.googleapis.com",
    "anthos.googleapis.com",
    "gkehub.googleapis.com",
    "trafficdirector.googleapis.com",
    "dns.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudbuild.googleapis.com",
    "containerregistry.googleapis.com",
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "eventarc.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "spanner.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com",
    "dataflow.googleapis.com",
    "datapipelines.googleapis.com",
    "notebooks.googleapis.com",
    "aiplatform.googleapis.com",
    "datastudio.googleapis.com",
    "dataform.googleapis.com",
    "datalineage.googleapis.com",
    "datacatalog.googleapis.com",
    "dataplex.googleapis.com",
    "datastream.googleapis.com",
    "workflows.googleapis.com",
    "workflowexecutions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "firebase.googleapis.com",
    "firestore.googleapis.com",
    "secretmanager.googleapis.com",
    "securitycenter.googleapis.com",
    "websecurityscanner.googleapis.com",
    "cloudaicompanion.googleapis.com",
    "servicehealth.googleapis.com",
    "recommender.googleapis.com",
    "identitytoolkit.googleapis.com"
  ])
}

resource "google_project_service" "service" {
  for_each = local.services
  project  = data.google_project.project.project_id
  service  = each.value
}

## OAuth Consent
resource "google_iap_brand" "project_brand" {
  project           = data.google_project.project.number
  support_email     = "admin@kentaiso.altostrat.com"
  application_title = "OAuth Consent"
}

## Storage
resource "google_storage_bucket" "project_storage" {
  project       = data.google_project.project.project_id
  name          = data.google_project.project.project_id
  location      = var.region
  force_destroy = true

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

## Org Policy
module "disable_policy_requireOsLogin" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "~> 5.4.0"
  project_id = data.google_project.project.project_id

  constraint       = "constraints/compute.requireOsLogin"
  policy_type      = "boolean"
  organization_id  = var.organization_id
  enforce          = false
  policy_for       = "project"
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_vmExternalIpAccess" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "~> 5.4.0"
  project_id = data.google_project.project.project_id

  constraint       = "constraints/compute.vmExternalIpAccess"
  policy_type      = "list"
  organization_id  = var.organization_id
  enforce          = false
  policy_for       = "project"
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_requireShieldedVm" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "~> 5.4.0"
  project_id = data.google_project.project.project_id

  constraint       = "constraints/compute.requireShieldedVm"
  policy_type      = "boolean"
  organization_id  = var.organization_id
  enforce          = false
  policy_for       = "project"
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_restrictVpcPeering" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "~> 5.4.0"
  project_id = data.google_project.project.project_id

  constraint       = "constraints/compute.restrictVpcPeering"
  policy_type      = "list"
  organization_id  = var.organization_id
  enforce          = false
  policy_for       = "project"
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_uniformBucketLevelAccess" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "~> 5.4.0"
  project_id = data.google_project.project.project_id

  constraint       = "constraints/storage.uniformBucketLevelAccess"
  policy_type      = "boolean"
  organization_id  = var.organization_id
  enforce          = true
  policy_for       = "project"
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_publicAccessPrevention" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "~> 5.4.0"
  project_id = data.google_project.project.project_id

  constraint       = "constraints/storage.publicAccessPrevention"
  policy_type      = "boolean"
  organization_id  = var.organization_id
  enforce          = true
  policy_for       = "project"
  exclude_projects = ["${var.organization_id}"]
}

module "allowed-policy-member-domains" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "5.4.0"
  project_id = data.google_project.project.project_id

  constraint      = "constraints/iam.allowedPolicyMemberDomains"
  policy_type     = "list"
  organization_id = var.organization_id
  policy_for      = "project"
  enforce         = false
}

## Service Acount
data "google_compute_default_service_account" "default" {
  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_project_iam_member" "allow_image_pull" {
  project = data.google_project.project.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_project_iam_member" "allow_logging_writer" {
  project = data.google_project.project.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_project_iam_member" "allow_pubsub_publisher" {
  project = data.google_project.project.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_project_iam_member" "allow_monitoring_writer" {
  project = data.google_project.project.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_project_iam_member" "allow_cloudsql_client" {
  project = data.google_project.project.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_project_iam_member" "allow_securitycommandcenter_serviceagent" {
  project = data.google_project.project.project_id
  role    = "roles/securitycenter.serviceAgent"
  member  = "serviceAccount:service-project-${data.google_project.project.number}@security-center-api.iam.gserviceaccount.com"

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_project_iam_member" "allow_securitycommandcenter_containerthreatagent" {
  project = data.google_project.project.project_id
  role    = "roles/containerthreatdetection.serviceAgent"
  member  = "serviceAccount:service-project-${data.google_project.project.number}@gcp-sa-ktd-hpsa.iam.gserviceaccount.com"

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_project_iam_member" "allow_securitycommandcenter_dspmagent" {
  project = data.google_project.project.project_id
  role    = "roles/dspm.serviceAgent"
  member  = "serviceAccount:service-project-${data.google_project.project.number}@gcp-sa-dspm-hpsa.iam.gserviceaccount.com"

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

## Secret
resource "google_secret_manager_secret" "mysql_little_quest_user_password" {
  project   = data.google_project.project.project_id
  secret_id = "mysql_little_quest_user_password"

  labels = {
    role = "mysql_little_quest_user_password"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_secret_manager_secret" "mysql_datastream_user_password" {
  project   = data.google_project.project.project_id
  secret_id = "mysql_datastream_user_password"

  labels = {
    role = "mysql_datastream_user_password"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_secret_manager_secret" "mysql_root_password" {
  project   = data.google_project.project.project_id
  secret_id = "mysql_root_password"

  labels = {
    role = "mysql_root_password"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_secret_manager_secret" "redis_password" {
  project   = data.google_project.project.project_id
  secret_id = "redis_password"

  labels = {
    role = "redis_password"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_secret_manager_secret" "github_token_dataform" {
  project   = data.google_project.project.project_id
  secret_id = "github_token_dataform"

  labels = {
    role = "github_token_dataform"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_secret_manager_secret" "argocd_client_id" {
  project   = data.google_project.project.project_id
  secret_id = "argocd_client_id"

  labels = {
    role = "argocd_client_id"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_secret_manager_secret" "argocd_client_secret" {
  project   = data.google_project.project.project_id
  secret_id = "argocd_client_secret"

  labels = {
    role = "argocd_client_secret"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_secret_manager_secret" "github_token_govargo_repository" {
  project   = data.google_project.project.project_id
  secret_id = "github_token_govargo_repository"

  labels = {
    role = "github_token_govargo_repository"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

## BigQuery dataset
resource "google_bigquery_dataset" "billing_export" {
  project = data.google_project.project.project_id

  dataset_id            = "all_billing_data"
  friendly_name         = "cloud_billing_billing_export"
  description           = "Cloud Billing data export to BigQuery"
  location              = var.region
  storage_billing_model = "PHYSICAL"

  labels = {
    role = "billing"
  }

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

resource "google_bigquery_dataset" "billing_board" {
  project = data.google_project.project.project_id

  dataset_id            = "billing_board"
  friendly_name         = "Cloud Billing Dashboard"
  description           = "BigQuery dataset where the BigQuery views for the billing dashboard"
  location              = var.region
  storage_billing_model = "PHYSICAL"

  labels = {
    role = "billing"
  }

  depends_on = [google_project_service.service, time_sleep.wait_150_seconds]
}

