data "google_project" "project" {
}

## All - Overview
resource "google_monitoring_dashboard" "all_overview_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/all_overview.json")
}

## HTTPS Load Balancing
resource "google_monitoring_dashboard" "https_loadbalancing_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/application_loadbalancing.json")
}

## GKE Cluster - Cluster View
resource "google_monitoring_dashboard" "gke_cluster_view_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/gke_cluster_view.json")
}

## GKE Cluster - Node View
resource "google_monitoring_dashboard" "gke_node_view_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/gke_node_view.json")
}

## GKE Cluster - Workload View
resource "google_monitoring_dashboard" "gke_workload_view_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/gke_workload_view.json")
}

## Kubernetes - kube-state-metrics
resource "google_monitoring_dashboard" "k8s_state_metrics_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/k8s_state_metrics.json")
}

## Kubernetes - Node Exporter
resource "google_monitoring_dashboard" "k8s_node_exporter_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/k8s_node_exporter.json")
}

## Kubernetes - Agones
resource "google_monitoring_dashboard" "k8s_agones_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/k8s_agones.json")
}

## Kubernetes - Open Match
resource "google_monitoring_dashboard" "k8s_open_match_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/k8s_open_match.json")
}

## Kubernetes - Go Processes
resource "google_monitoring_dashboard" "k8s_go_process_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/k8s_go_processes.json")
}

## Kubernetes - Little Quest
resource "google_monitoring_dashboard" "k8s_little_quest_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/k8s_little_quest.json")
}

## Kubernetes - Istio Service
resource "google_monitoring_dashboard" "k8s_istio_service_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/k8s_istio_service.json")
}

## Kubernetes - Envoy Network
resource "google_monitoring_dashboard" "k8s_envoy_network_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/k8s_envoy_network.json")
}

## Cloud Service Mesh
resource "google_monitoring_dashboard" "cloud_service_mesh_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/cloud_service_mesh.json")
}

## Cloud Spanner Instance
resource "google_monitoring_dashboard" "spanner_instance_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/cloud_spanner.json")
}

## Cloud SQL for MySQL
resource "google_monitoring_dashboard" "cloudsql_mysql_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/cloudsql_mysql.json")
}

## Cloud Memorystore for Redis
resource "google_monitoring_dashboard" "memorystore_redis_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/memorystore_redis.json")
}

## Cloud Pub/Sub
resource "google_monitoring_dashboard" "pubsub_monitoring_dashboard" {
  project = data.google_project.project.project_id
  dashboard_json = templatefile("${path.module}/files/cloud_pubsub.json", {
    project_id = data.google_project.project.project_id
  })
}

## Cloud Run
resource "google_monitoring_dashboard" "cloudrun_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/cloud_run.json")
}

## Cloud Functions
resource "google_monitoring_dashboard" "cloudfunctions_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/cloud_functions.json")
}

## Cloud NAT
resource "google_monitoring_dashboard" "nat_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/cloud_nat.json")
}

## Cloud DNS
resource "google_monitoring_dashboard" "dns_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/cloud_dns.json")
}

## DataStream
resource "google_monitoring_dashboard" "datastream_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = templatefile("${path.module}/files/datastream.json", {
    project_id = data.google_project.project.project_id
  })
}

## Cloud Scheduler + Cloud Workflows
resource "google_monitoring_dashboard" "scheduler_workflows_monitoring_dashboard" {
  project        = data.google_project.project.project_id
  dashboard_json = file("files/cloud_workflows.json")
}
