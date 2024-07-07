## Service Account
resource "google_project_iam_custom_role" "pubsub_custom_publisher" {
  role_id     = "pubsub_custom_publisher"
  title       = "Custom Pub/Sub publisher"
  description = "Custom Pub/Sub pulisher and create topic role"
  permissions = ["pubsub.topics.publish", "pubsub.topics.get", "pubsub.topics.create"]
  stage       = "GA"
}

module "little_quest_server_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names        = ["little-quest-server"]
  display_name = "Little Quest Server ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/secretmanager.secretAccessor",
    "${data.google_project.project.project_id}=>roles/monitoring.viewer",
    "${data.google_project.project.project_id}=>roles/monitoring.metricWriter",
    "${data.google_project.project.project_id}=>roles/cloudprofiler.agent",
    "${data.google_project.project.project_id}=>roles/cloudsql.client",
    "${data.google_project.project.project_id}=>roles/spanner.databaseUser",
    "${data.google_project.project.project_id}=>projects/${data.google_project.project.project_id}/roles/${google_project_iam_custom_role.pubsub_custom_publisher.role_id}",
  ]
}

module "little_quest_server_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  service_accounts = [module.little_quest_server_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[little-quest-server/little-quest-server]"
    ]
  }
  depends_on = [module.little_quest_server_sa]
}

module "opentelemetry_collector_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names         = ["opentelemetry-collector"]
  display_name  = "OpenTelemetry Collector ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/cloudtrace.agent"]
}

module "opentelemetry_collector_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  service_accounts = [module.opentelemetry_collector_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[tracing/opentelemetry-collector]"
    ]
  }
  depends_on = [module.opentelemetry_collector_sa]
}
