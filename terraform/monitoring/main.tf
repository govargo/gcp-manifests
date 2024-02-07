data "google_project" "project" {
}

## HTTPS Load Balancing
resource "google_monitoring_dashboard" "https_loadbalancing_monitoring_dashboard" {
  project   = data.google_project.project.project_id
  dashboard_json = file("files/application_loadbalancing.json")
}

# Cloud Spanner Instance
resource "google_monitoring_dashboard" "spanner_instance_monitoring_dashboard" {
  project   = data.google_project.project.project_id
  dashboard_json = file("files/cloud_spanner.json")
}

# Cloud SQL for MySQL
resource "google_monitoring_dashboard" "cloudsql_mysql_monitoring_dashboard" {
  project   = data.google_project.project.project_id
  dashboard_json = file("files/cloudsql_mysql.json")
}

## Cloud Memorystore for Redis
resource "google_monitoring_dashboard" "memorystore_redis_monitoring_dashboard" {
  project   = data.google_project.project.project_id
  dashboard_json = file("files/memorystore_redis.json")
}

## BigQuery
data "github_repository_file" "bigquery_query_monitoring_dashboard_json" {
  repository          = "GoogleCloudPlatform/monitoring-dashboard-samples"
  branch              = "master"
  file                = "dashboards/bigdata/bigquery-monitoring.json"
}

resource "google_monitoring_dashboard" "bigquery_query_monitoring_dashboard" {
  project   = data.google_project.project.project_id
  dashboard_json = data.github_repository_file.bigquery_query_monitoring_dashboard_json.content
}
