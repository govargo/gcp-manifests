data "google_project" "project" {
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
