## Notification channel
resource "google_monitoring_notification_channel" "email_notification" {
  display_name = "Gmail Notification Channel"
  type         = "email"
  labels = {
    email_address = "kentaiso@google.com"
  }
  force_delete = false
}

## Alert Policy

## GCE
resource "google_monitoring_alert_policy" "gce_high_cpu_utilization" {
  display_name = "VM Instance - High CPU Utilization"
  documentation {
    content   = "This alert fires when the CPU utilization on the VM instance ($${metric.labels.instance_name}) rises above 80% for 5 minutes or more."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "VM Instance - High CPU utilization"
    condition_threshold {
      filter     = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_NONE"
        per_series_aligner   = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 0.8
    }
  }

  user_labels = {
    product = "gce"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "gce_high_disk_utilization" {
  display_name = "VM Instance - High Disk Utilization"
  documentation {
    content   = "s alert fires when the disk utilization on the VM instance ($${metric.labels.instance_name}) rises above 95% for 5 minutes or more."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "VM Instance - High Disk utilization"
    condition_threshold {
      filter     = "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/disk/percent_used\" AND metric.labels.state = \"used\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_NONE"
        per_series_aligner   = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 95
    }
  }

  user_labels = {
    product = "gce"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "gce_high_memory_utilization" {
  display_name = "VM Instance - High Memory Utilization"
  documentation {
    content   = "s alert fires when the memory utilization on the VM instance ($${metric.labels.instance_name}) rises above 90% for 5 minutes or more."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "VM Instance - High Memory utilization"
    condition_threshold {
      filter     = "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/memory/percent_used\" AND metric.labels.state = \"used\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_NONE"
        per_series_aligner   = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 90
    }
  }

  user_labels = {
    product = "gce"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "gce_host_error" {
  display_name = "VM Instance - Host Error Log Detected"
  documentation {
    content   = "This alert fires when any host error is detected on the VM instance ($${metric.labels.instance_name}) based on system_event logs, limited to notifying once per hour."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "WARNING"
  combiner = "OR"
  conditions {
    display_name = "VM Instance - Host Error Log Detected"
    condition_matched_log {
      filter = "log_id(\"cloudaudit.googleapis.com/system_event\") AND operation.producer=\"compute.instances.hostError\""
    }
  }

  user_labels = {
    product = "gce"
  }

  alert_strategy {
    notification_rate_limit {
      period = "3600s"
    }
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

## GKE and Container
resource "google_monitoring_alert_policy" "gke_container_high_cpu_limit_utilization" {
  display_name = "GKE Container - High CPU Limit Utilization (all containers)"
  documentation {
    content   = "- Containers that exceed CPU utilization limit are CPU throttled. To avoid application slowdown and unresponsiveness, keep CPU usage below the CPU utilization limit [View Documentation](https://cloud.google.com/blog/products/containers-kubernetes/kubernetes-best-practices-resource-requests-and-limits).\n- If alerts tend to be false positive or noisy, consider visiting the alert policy page and changing the threshold, the rolling (alignment) window, and the retest (duration) window. [View Documentation](https://cloud.google.com/monitoring/alerts/concepts-indepth)"
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "GKE Container has high CPU limit utilization"
    condition_threshold {
      filter     = "resource.type = \"k8s_container\" AND metric.type = \"kubernetes.io/container/cpu/limit_utilization\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_NONE"
        per_series_aligner   = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 0.9
    }
  }

  user_labels = {
    product = "gke"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "gke_container_high_memory_limit_utilization" {
  display_name = "GKE Container - High Memory Limit Utilization (all containers)"
  documentation {
    content   = "- Containers that exceed Memory utilization limit are terminated. To avoid Out of Memory (OOM) failures, keep memory usage below the memory utilization limit [View Documentation](https://cloud.google.com/blog/products/containers-kubernetes/kubernetes-best-practices-resource-requests-and-limits).\n- If alerts tend to be false positive or noisy, consider visiting the alert policy page and changing the threshold, the rolling (alignment) window, and the retest (duration) window. [View Documentation](https://cloud.google.com/monitoring/alerts/concepts-indepth)"
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "GKE Container has high memory limit utilization"
    condition_threshold {
      filter     = "resource.type = \"k8s_container\" AND metric.type = \"kubernetes.io/container/memory/limit_utilization\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "60s"
        cross_series_reducer = "REDUCE_NONE"
        per_series_aligner   = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 0.9
    }
  }

  user_labels = {
    product = "gke"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "gke_container_restarts" {
  display_name = "GKE Container - Restarts (all containers)"
  documentation {
    content   = "- Container restarts are commonly caused by memory/cpu usage issues and application failures.\n- By default, this alert notifies an incident when there is more than 1 container restart in a 5 minute window. If alerts tend to be false positive or noisy, consider visiting the alert policy page and changing the threshold, the rolling (alignment) window, and the retest (duration) window. [View Documentation](https://cloud.google.com/monitoring/alerts/concepts-indepth)."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "WARNING"
  combiner = "OR"
  conditions {
    display_name = "GKE container has restarted"
    condition_threshold {
      filter     = "resource.type = \"k8s_container\" AND metric.type = \"kubernetes.io/container/restart_count\" AND resource.labels.container_name != \"config-reloader\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_NONE"
        per_series_aligner   = "ALIGN_DELTA"
      }
      trigger {
        count = 1
      }
      threshold_value = 1
    }
  }

  user_labels = {
    product = "gke"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "gke_ingress_high_latency" {
  display_name = "GKE Ingress - High Latency"
  documentation {
    content   = "If alerts tend to be false positive or noisy, consider visiting the alert policy page and changing the threshold, the rolling (alignment) window, and the retest (duration) window. [Alerting policies documentation](https://cloud.google.com/monitoring/alerts/concepts-indepth), [MQL documentation](https://cloud.google.com/monitoring/mql/alerts)"
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "High p95 latency for a URL path in Ingress"
    condition_threshold {
      filter = "resource.type = \"https_lb_rule\" AND resource.labels.backend_name = \"k8s1-9366847e-little-quest-server-little-quest-serve-8-c7296101\" AND resource.labels.backend_type = \"NETWORK_ENDPOINT_GROUP\" AND metric.type = \"loadbalancing.googleapis.com/https/total_latencies\""
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields = [
          "resource.label.matched_url_path_rule"
        ]
        per_series_aligner = "ALIGN_DELTA"
      }
      comparison = "COMPARISON_GT"
      duration   = "0s"
      trigger {
        count = 1
      }
      threshold_value = 10000
    }
  }

  user_labels = {
    product = "gke"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "gke_ingress_server_error" {
  display_name = "GKE Ingress - High Server Error Rate(5xx)"
  documentation {
    content   = "If alerts tend to be false positive or noisy, consider visiting the alert policy page and changing the threshold, the rolling (alignment) window, and the retest (duration) window. [Alerting policies documentation](https://cloud.google.com/monitoring/alerts/concepts-indepth), [MQL documentation](https://cloud.google.com/monitoring/mql/alerts)"
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Server Error Rate(5xx) is high for a URL path"
    condition_threshold {
      filter = "resource.type = \"https_lb_rule\" AND resource.labels.backend_name = \"k8s1-9366847e-little-quest-server-little-quest-serve-8-c7296101\" AND metric.labels.response_code >= 500 AND metric.type = \"loadbalancing.googleapis.com/https/request_count\""
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields = [
          "resource.label.matched_url_path_rule"
        ]
        per_series_aligner = "ALIGN_RATE"
      }
      comparison = "COMPARISON_GT"
      duration   = "0s"
      trigger {
        count = 1
      }
      threshold_value = 5
    }
  }
  alert_strategy {
    auto_close = "604800s"
  }
}

## Cloud Spanner
resource "google_monitoring_alert_policy" "cloud_spanner_instance_high_cpu" {
  display_name = "Cloud Spanner - High-priority CPU Utilization"
  documentation {
    content   = "This alert fires when the high-priority CPU utilization on Cloud Spanner instance ($${metric.labels.instance_id}) rises above 65% for 10 minutes or more."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Cloud Spanner - High-priority CPU Utilization"
    condition_threshold {
      filter     = "resource.type = \"spanner_instance\" AND metric.type = \"spanner.googleapis.com/instance/cpu/utilization_by_priority\" AND metric.labels.priority = \"high\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "600s"
        cross_series_reducer = "REDUCE_SUM"
        per_series_aligner   = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 0.65
    }
  }

  user_labels = {
    product = "cloud_spanner"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloud_spanner_instance_high_rolling_average_cpu" {
  display_name = "Cloud Spanner - High Rolling Average CPU Utilization"
  documentation {
    content   = "This alert fires when the high rolling average CPU utilization on Cloud Spanner instance ($${metric.labels.instance_id}) rises above 90% for 10 minutes or more."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Cloud Spanner - High Rolling Average CPU Utilization"
    condition_threshold {
      filter     = "resource.type = \"spanner_instance\" AND metric.type = \"spanner.googleapis.com/instance/cpu/smoothed_utilization\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "600s"
        cross_series_reducer = "REDUCE_SUM"
        per_series_aligner   = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 0.9
    }
  }

  user_labels = {
    product = "cloud_spanner"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloud_spanner_instance_high_disk_utilization" {
  display_name = "Cloud Spanner - High Disk Utilization"
  documentation {
    content   = "This alert fires when the high disk utilization on Cloud Spanner instance ($${metric.labels.instance_id}) rises above 90% for 10 minutes or more."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Cloud Spanner - High Disk Utilization"
    condition_threshold {
      filter     = "resource.type = \"spanner_instance\" AND metric.type = \"spanner.googleapis.com/instance/storage/utilization\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "600s"
        cross_series_reducer = "REDUCE_SUM"
        per_series_aligner   = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 0.9
    }
  }

  user_labels = {
    product = "cloud_spanner"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloud_spanner_instance_high_read_transaction_latency" {
  display_name = "Cloud Spanner - High Read Transaction Latency"
  documentation {
    content   = "This alert fires when the high read transaction latency on Cloud Spanner instance ($${metric.labels.instance_id})"
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Cloud Spanner - High Read Transaction Latency"
    condition_threshold {
      filter     = "resource.type = \"spanner_instance\" AND metric.type = \"spanner.googleapis.com/api/request_latencies\" AND metric.labels.method = monitoring.regex.full_match(\"ExecuteBatchDml|ExecuteSql|ExecuteStreamingSql|Read|StreamingRead\")"
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_PERCENTILE_99"
      }
      trigger {
        count = 1
      }
      threshold_value = 3
    }
  }

  user_labels = {
    product = "cloud_spanner"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloud_spanner_instance_high_write_transaction_latency" {
  display_name = "Cloud Spanner - High Write Transaction Latency"
  documentation {
    content   = "This alert fires when the high write transaction latency on Cloud Spanner instance ($${metric.labels.instance_id})"
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Cloud Spanner - High Write Transaction Latency"
    condition_threshold {
      filter     = "resource.type = \"spanner_instance\" AND metric.type = \"spanner.googleapis.com/api/request_latencies\" AND metric.labels.method = \"Commit\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_PERCENTILE_99"
      }
      trigger {
        count = 1
      }
      threshold_value = 3
    }
  }

  user_labels = {
    product = "cloud_spanner"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloud_spanner_instance_high_lock_wait_time" {
  display_name = "Cloud Spanner - High Lock Wait Time"
  documentation {
    content   = "This alert fires when the high lock wait time on Cloud Spanner instance ($${metric.labels.instance_id})"
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Cloud Spanner - High Lock Wait Time"
    condition_threshold {
      filter     = "resource.type = \"spanner_instance\" AND metric.type = \"spanner.googleapis.com/lock_stat/total/lock_wait_time\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_SUM"
        per_series_aligner   = "ALIGN_RATE"
      }
      trigger {
        count = 1
      }
      threshold_value = 3
    }
  }

  user_labels = {
    product = "cloud_spanner"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

## Cloud SQL
resource "google_monitoring_alert_policy" "cloudsql_instance_failed_state" {
  display_name = "Cloud SQL - Instance in Failed State"
  documentation {
    content   = "This alert fires when any Cloud SQL instance has stopped working and has entered an error state. The cause should be investigated and the instance should be restored from a backup. For more information on managing instances and troubleshooting failed instances visit: https://cloud.google.com/sql/docs/troubleshooting#managing-instances"
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Cloud SQL - Instance in Failed State"
    condition_threshold {
      filter     = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/instance_state\" AND metric.labels.state = \"FAILED\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = [
          "metric.label.state"
        ]
        per_series_aligner = "ALIGN_COUNT_TRUE"
      }
      trigger {
        count = 1
      }
      threshold_value = 1
    }
  }

  user_labels = {
    product = "cloud_sql"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloudsql_instance_high_cpu" {
  display_name = "Cloud SQL - High CPU Utilization"
  documentation {
    content   = "This alert fires when the high CPU utilization on Cloud SQL instance rises above 80% for 5 minutes or more."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Cloud SQL - High CPU Utilization"
    condition_threshold {
      filter     = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/cpu/utilization\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_SUM"
        per_series_aligner   = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 0.8
    }
  }

  user_labels = {
    product = "cloud_sql"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloudsql_instance_high_memory" {
  display_name = "Cloud SQL - High Memory Utilization"
  documentation {
    content   = "This alert fires when the high memory utilization on Cloud SQL instance rises above 80% for 5 minutes or more."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Cloud SQL - High Memory Utilization"
    condition_threshold {
      filter     = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/memory/components\" AND metric.label.component = \"Usage\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_SUM"
        per_series_aligner   = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 80
    }
  }

  user_labels = {
    product = "cloud_sql"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloudsql_instance_high_disk" {
  display_name = "Cloud SQL - High Disk Utilization"
  documentation {
    content   = "This alert fires when the high disk utilization on Cloud SQL instance rises above 90% for 5 minutes or more."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Cloud SQL - High Disk Utilization"
    condition_threshold {
      filter     = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/disk/utilization\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_SUM"
        per_series_aligner   = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 90
    }
  }

  user_labels = {
    product = "cloud_sql"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloudsql_database_many_abort_connection" {
  display_name = "Cloud SQL - Database Many Aborted Connection"
  documentation {
    content   = "This alert fires when the number of aborted connection on a Cloud SQL instance exceeds a threshold. This could indicate network issues or problems with your database configuration."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "WARNING"
  combiner = "OR"
  conditions {
    display_name = "Cloud SQL - Database Many Aborted Connection"
    condition_threshold {
      filter     = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/mysql/aborted_connects_count\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_SUM"
        per_series_aligner   = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 10
    }
  }

  user_labels = {
    product = "cloud_sql"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloudsql_database_exceeded_max_connection" {
  display_name = "Cloud SQL - Database Exceeded Max Connection"
  documentation {
    content   = "This alert fires when the number of max connection on a Cloud SQL instance exceeds a threshold."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Cloud SQL - Database Exceeded Max Connection"
    condition_threshold {
      filter     = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/network/connections\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_SUM"
        per_series_aligner   = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 250
    }
  }

  user_labels = {
    product = "cloud_sql"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloudsql_database_slow_query" {
  display_name = "Cloud SQL - Database Slow Query Detected"
  documentation {
    content   = "The slow queries are collected from mysql_slow logs. More specific queries can be filtered using the `jsonPayload.message` field shown in the filter below. Additionally, different max query times can also be filtered using `jsonPayload.queryTime` field."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "WARNING"
  combiner = "OR"
  conditions {
    display_name = "Cloud SQL - Database Slow Query Detected"
    condition_matched_log {
      filter = "resource.type=\"cloudsql_database\" insertId=~\".*slow.*\" textPayload:\"!started with\""
    }
  }

  user_labels = {
    product = "cloud_sql"
  }

  alert_strategy {
    notification_rate_limit {
      period = "3600s"
    }
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

## Memorystore for Redis
resource "google_monitoring_alert_policy" "memorystore_redis_high_cpu_utilization" {
  display_name = "Memorystore for Redis - High CPU utilization"
  documentation {
    content   = "This alert fires if the  Redis CPU Utilization goes above the set threshold. The utilization is measured on a scale of 0 to 1. "
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Memorystore for Redis - High CPU utilization"
    condition_threshold {
      filter     = "resource.type = \"redis_instance\" AND metric.type = \"redis.googleapis.com/stats/cpu_utilization_main_thread\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = [
          "resource.label.node_id"
        ]
        per_series_aligner = "ALIGN_RATE"
      }
      trigger {
        count = 1
      }
      threshold_value = 0.9
    }
  }

  user_labels = {
    product = "memorystore_redis"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "memorystore_redis_standard_instance_failover" {
  display_name = "Memorystore for Redis - Standard Instance Failover"
  documentation {
    content   = "This alert fires if failover occurs for a standard tier instance. To ensure that alerts always fire, we recommend keeping the threshold value to 0"
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Memorystore for Redis - Standard Instance Failover"
    condition_threshold {
      filter     = "resource.type = \"redis_instance\" AND metric.type = \"redis.googleapis.com/replication/role\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_STDDEV"
      }
      trigger {
        count = 1
      }
      threshold_value = 0
    }
  }

  user_labels = {
    product = "memorystore_redis"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "memorystore_redis_system_memory_utilization" {
  display_name = "Memorystore for Redis - High System Memory Utilization"
  documentation {
    content   = "This alert fires if the system memory utilization is above the set threshold. The utilization is measured on a scale of 0 to 1."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Memorystore for Redis - High System Memory Utilization"
    condition_threshold {
      filter     = "resource.type = \"redis_instance\" AND metric.type = \"redis.googleapis.com/stats/memory/system_memory_usage_ratio\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
      trigger {
        count = 1
      }
      threshold_value = 0.8
    }
  }

  user_labels = {
    product = "memorystore_redis"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

## Network
resource "google_monitoring_alert_policy" "network_incident_alert" {
  display_name = "Network - Network Incident Detected"
  documentation {
    content   = "Alerts when a network incident happens, based on service_health_event logs."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Network - Network Incident Detected"
    condition_matched_log {
      filter = "logName=\"projects/${data.google_project.project.project_id}/logs/networkmanagement.googleapis.com%2Fservice_health_event\""
    }
  }

  user_labels = {
    product = "network"
  }

  alert_strategy {
    notification_rate_limit {
      period = "3600s"
    }
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "network_high_packet_loss" {
  display_name = "Network - High packet loss"
  documentation {
    content   = "This alert indicates that the Packet Loss exceeded 5% for 5 minutes for a specific region pair."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Network - Packet Loss higher than 5%"
    condition_threshold {
      filter     = "resource.type = \"gce_zone_network_health\" AND metric.type = \"networking.googleapis.com/cloud_netslo/active_probing/probe_count\" AND metric.labels.result = \"failure\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = [
          "resource.label.region",
          "metric.label.remote_region"
        ]
        per_series_aligner = "ALIGN_RATE"
      }
      trigger {
        count = 1
      }
      threshold_value = 0.5
    }
  }

  user_labels = {
    product = "network"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

## Cloud NAT
resource "google_monitoring_alert_policy" "cloud_nat_allocation_failed" {
  display_name = "Cloud NAT - Allocation Failed"
  documentation {
    content   = "This alert indicates that there is a failure in allocating NAT IPs to any VM in the NAT gateway."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Cloud NAT - Allocation Failed"
    condition_threshold {
      filter     = "resource.type = \"nat_gateway\" AND metric.type = \"router.googleapis.com/nat/nat_allocation_failed\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_COUNT_TRUE"
        group_by_fields = [
          "resource.label.gateway_name"
        ]
        per_series_aligner = "ALIGN_NEXT_OLDER"
      }
      trigger {
        count = 1
      }
      threshold_value = 1
    }
  }

  user_labels = {
    product = "cloud_nat"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloud_nat_high_dropped_sent_packet" {
  display_name = "Cloud NAT - High Dropped Sent Packet"
  documentation {
    content   = "This alert indicates that there are failures for sent packets dropped by the NAT gateway."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Cloud NAT - High Dropped Sent Packet"
    condition_threshold {
      filter     = "resource.type = \"nat_gateway\" AND metric.type = \"router.googleapis.com/nat/dropped_sent_packets_count\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = [
          "resource.label.gateway_name",
          "metric.label.reason"
        ]
        per_series_aligner = "ALIGN_RATE"
      }
      trigger {
        count = 1
      }
      threshold_value = 1
    }
  }

  user_labels = {
    product = "cloud_nat"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

## Cloud Run
resource "google_monitoring_alert_policy" "cloud_run_high_execution_time" {
  display_name = "Cloud Run - High Execution Time"
  documentation {
    content   = "This alert fires when the execution time of Cloud Run ($${metric.labels.service_name}) exceeds 300 milliseconds for 5 minutes or more."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "WARNING"
  combiner = "OR"
  conditions {
    display_name = "Cloud Run - High Execution Time"
    condition_threshold {
      filter     = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/request_latencies\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_PERCENTILE_99"
      }
      trigger {
        count = 1
      }
      threshold_value = 300
    }
  }

  user_labels = {
    product = "cloud_run"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloud_run_high_error_rate" {
  display_name = "Cloud Run - High Error Rate"
  documentation {
    content   = "This alert fires when the execution error for ($${metric.labels.service_name}) exceeds for 5 minutes or more."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "WARNING"
  combiner = "OR"
  conditions {
    display_name = "Cloud Run - High Error Rate"
    condition_threshold {
      filter     = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class != \"2xx\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_SUM"
        per_series_aligner   = "ALIGN_RATE"
      }
      trigger {
        count = 1
      }
      threshold_value = 1
    }
  }

  user_labels = {
    product = "cloud_run"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

## Cloud Functions
resource "google_monitoring_alert_policy" "cloud_function_high_execution_time" {
  display_name = "Cloud Function - High Execution Time"
  documentation {
    content   = "This alert fires when the execution time of Cloud Function ($${metric.labels.function_name}) exceeds 300 milliseconds for 5 minutes or more."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "WARNING"
  combiner = "OR"
  conditions {
    display_name = "Cloud Function - High Execution Time"
    condition_threshold {
      filter     = "resource.type = \"cloud_function\" AND metric.type = \"cloudfunctions.googleapis.com/function/execution_times\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_PERCENTILE_99"
      }
      trigger {
        count = 1
      }
      threshold_value = 300000000 # 300ms
    }
  }

  user_labels = {
    product = "cloud_function"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

resource "google_monitoring_alert_policy" "cloud_function_high_error_rate" {
  display_name = "Cloud Function - High Error Rate"
  documentation {
    content   = "This alert fires when the execution error for ($${metric.labels.function_name}) exceeds for 5 minutes or more."
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "WARNING"
  combiner = "OR"
  conditions {
    display_name = "Cloud Function - High Error Rate"
    condition_threshold {
      filter     = "resource.type = \"cloud_function\" AND metric.type = \"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.status != \"ok\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_SUM"
        per_series_aligner   = "ALIGN_RATE"
      }
      trigger {
        count = 1
      }
      threshold_value = 1
    }
  }

  user_labels = {
    product = "cloud_function"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

## BigQuery
resource "google_monitoring_alert_policy" "bigquery_query_execution_time" {
  display_name = "BigQuery - High query execution time"
  documentation {
    content   = "This alert indicates that the 99th percentile of the execution time of a BigQuery query exceeds a user-defined limit"
    mime_type = "text/markdown"
  }
  enabled  = true
  severity = "WARNING"
  combiner = "OR"
  conditions {
    display_name = "BigQuery - High query execution time"
    condition_threshold {
      filter     = "resource.type = \"bigquery_project\" AND metric.type = \"bigquery.googleapis.com/query/execution_times\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_PERCENTILE_99"
        group_by_fields = [
          "metric.label.priority"
        ]
      }
      trigger {
        count = 1
      }
      threshold_value = 60
    }
  }

  user_labels = {
    product = "bigquery"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}

## Quota
resource "google_monitoring_alert_policy" "quota_exceeded" {
  display_name = "Quota Exceeded"

  enabled  = true
  severity = "ERROR"
  combiner = "OR"
  conditions {
    display_name = "Quota Exceeded"
    condition_threshold {
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_COUNT_TRUE"
        cross_series_reducer = "REDUCE_SUM"
      }
      comparison      = "COMPARISON_GT"
      duration        = "0s"
      filter          = "resource.type=\"consumer_quota\" AND metric.type=\"serviceruntime.googleapis.com/quota/exceeded\""
      threshold_value = 1
      trigger {
        count = 1
      }
    }
  }

  user_labels = {
    product = "quota"
  }

  alert_strategy {
    auto_close = "604800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_notification.name]
}
