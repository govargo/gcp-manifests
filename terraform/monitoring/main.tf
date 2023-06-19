data "google_project" "project" {
}

## HTTPS Load Balancing
data "github_repository_file" "https_loadbalancing_monitoring_dashboard_json" {
  repository          = "GoogleCloudPlatform/monitoring-dashboard-samples"
  branch              = "master"
  file                = "dashboards/networking/https-loadbalancer-monitoring.json"
}

resource "google_monitoring_dashboard" "https_loadbalancing_monitoring_dashboard" {
  project   = data.google_project.project.project_id
  dashboard_json = data.github_repository_file.https_loadbalancing_monitoring_dashboard_json.content
}

# Cloud Spanner Instance
data "github_repository_file" "spanner_instance_monitoring_dashboard_json" {
  repository          = "GoogleCloudPlatform/monitoring-dashboard-samples"
  branch              = "master"
  file                = "dashboards/spanner/spanner.json"
}

resource "google_monitoring_dashboard" "spanner_instance_monitoring_dashboard" {
  project   = data.google_project.project.project_id
  dashboard_json = data.github_repository_file.spanner_instance_monitoring_dashboard_json.content
}

# Cloud SQL
data "github_repository_file" "cloudsql_general_monitoring_dashboard_json" {
  repository          = "GoogleCloudPlatform/monitoring-dashboard-samples"
  branch              = "master"
  file                = "dashboards/google-cloudsql/cloudsql-general.json"
}

resource "google_monitoring_dashboard" "cloudsql_general_monitoring_dashboard" {
  project   = data.google_project.project.project_id
  dashboard_json = data.github_repository_file.cloudsql_general_monitoring_dashboard_json.content
}

data "github_repository_file" "cloudsql_transactions_monitoring_dashboard_json" {
  repository          = "GoogleCloudPlatform/monitoring-dashboard-samples"
  branch              = "master"
  file                = "dashboards/google-cloudsql/cloudsql-transactions.json"
}

resource "google_monitoring_dashboard" "cloudsql_transactions_monitoring_dashboard" {
  project   = data.google_project.project.project_id
  dashboard_json = data.github_repository_file.cloudsql_transactions_monitoring_dashboard_json.content
}

## Cloud Memorystore for Redis
data "github_repository_file" "memorystore_redis_monitoring_dashboard_json" {
  repository          = "GoogleCloudPlatform/monitoring-dashboard-samples"
  branch              = "master"
  file                = "dashboards/redis/redis-usage.json"
}

resource "google_monitoring_dashboard" "memorystore_redis_monitoring_dashboard" {
  project   = data.google_project.project.project_id
  dashboard_json = data.github_repository_file.memorystore_redis_monitoring_dashboard_json.content
}
