data "google_project" "project" {
}

import {
  id = "projects/kentaiso-330205/locations/global/buckets/_Default"
  to = google_logging_project_bucket_config._default_bucket_log_analytics_enabled
}

## Enable LogAnalytics
resource "google_logging_project_bucket_config" "_default_bucket_log_analytics_enabled" {
  project  = data.google_project.project.id
  location = "global"

  bucket_id        = "_Default"
  description      = "Default bucket"
  enable_analytics = true
  locked           = false
  retention_days   = 30
}

## Exclude Log for Cost Reduction
resource "google_logging_project_exclusion" "load_balancing_exclude_2xx_code" {
  name = "load-balancing-exclude-2xx-code"

  description = "Exclude Load Balancing logs for 2xx-3xx status code"

  filter = <<EOF
resource.type="http_load_balancer" AND severity>=INFO
httpRequest.status>=200 AND httpRequest.status<=400
EOF
}

resource "google_logging_project_exclusion" "k8s_container_exclude_kube_system" {
  name = "k8s-container-exclude-kube-system"

  description = "Exclude kube-system info log for all clusters"

  filter = <<EOF
resource.type="k8s_container"
resource.labels.namespace_name="kube-system"
severity=INFO
EOF
}

resource "google_logging_project_exclusion" "k8s_container_exclude_managed_prometheus" {
  name = "k8s-container-exclude-managed-prometheus"

  description = "Exclude managed prometheus info log for all clusters"

  filter = <<EOF
resource.type="k8s_container"
resource.labels.namespace_name="gmp-system" OR resource.labels.namespace_name="gmp-public"
severity=INFO
EOF
}

resource "google_logging_project_exclusion" "k8s_container_exclude_argocd" {
  name = "k8s-container-exclude-argocd"

  description = "Exclude argocd all log for all clusters"

  filter = <<EOF
resource.type="k8s_container"
resource.labels.namespace_name="argocd"
EOF
}

resource "google_logging_project_exclusion" "k8s_container_exclude_falco" {
  name = "k8s-container-exclude-falco"

  description = "Exclude falco all log for all clusters"

  filter = <<EOF
resource.type="k8s_container"
resource.labels.namespace_name="falco"
EOF
}

resource "google_logging_project_exclusion" "k8s_container_exclude_gke_mcs" {
  name = "k8s-container-exclude-gke-mcs"

  description = "Exclude GKE multi cluster service all log for all clusters"

  filter = <<EOF
resource.type="k8s_container"
resource.labels.namespace_name="gke-mcs"
EOF
}

resource "google_logging_project_exclusion" "k8s_container_exclude_little_quest_server_healthcheck" {
  name = "k8s-container-exclude-little-quest-server-healthcheck"

  description = "Exclude little quest server health check log"

  filter = <<EOF
resource.type="k8s_container"
resource.labels.namespace_name="little-quest-server"
textPayload=~".*GET /healthz HTTP/1.1.*" OR textPayload=~".*GET /readiness HTTP/1.1.*" OR textPayload=~".*GET /metrics HTTP/1.1.*"
EOF
}

resource "google_logging_project_exclusion" "k8s_container_exclude_little_quest_realtime_healthcheck" {
  name = "k8s-container-exclude-little-quest-realtime-healthcheck"

  description = "Exclude little quest realtime health check log"

  filter = <<EOF
resource.type="k8s_container"
resource.labels.namespace_name="corp-0"
textPayload=~".*GET /healthz HTTP/1.1.*" OR textPayload=~".*GET /readiness HTTP/1.1.*" OR textPayload=~".*GET /metrics HTTP/1.1.*"
EOF
}

## Cloud Logging Sink for Little Quest
resource "google_logging_project_sink" "kpi_action_log" {
  project = data.google_project.project.project_id

  name        = "kpi_action_log"
  destination = "bigquery.googleapis.com/projects/${data.google_project.project.project_id}/datasets/prod_little_quest_datalake"
  filter      = <<EOF
resource.type="k8s_container"
resource.labels.namespace_name="little-quest"
resource.labels.container_name="little-quest"
jsonPayload.message=~"(\[Action\]|\[KPI\])"
EOF

  unique_writer_identity = true
  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_project_iam_member" "kpi_action_log_writer" {
  project = data.google_project.project.project_id

  role   = "roles/bigquery.dataEditor"
  member = google_logging_project_sink.kpi_action_log.writer_identity
}

## Cloud Logging Sink for BigQuery Audit Log for cost analytics
resource "google_logging_project_sink" "bigquery_audit_log" {
  project = data.google_project.project.project_id

  name        = "bigquery_audit_log_for_cost"
  destination = "bigquery.googleapis.com/projects/${data.google_project.project.project_id}/datasets/bigquery_cost_analysis"
  filter      = <<EOF
resource.type="bigquery_resource"
EOF

  unique_writer_identity = true
  bigquery_options {
    use_partitioned_tables = false
  }
}

resource "google_project_iam_member" "bigquery_audit_log_writer" {
  project = data.google_project.project.project_id

  role   = "roles/bigquery.dataEditor"
  member = google_logging_project_sink.bigquery_audit_log.writer_identity
}
