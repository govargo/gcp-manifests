data "google_project" "project" {
}

data "google_compute_default_service_account" "default" {
}

module "app-0" {
  source                               = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version                              = "30.2.0"
  project_id                           = data.google_project.project.project_id
  name                                 = "${var.env}-app-0"
  regional                             = true
  region                               = var.region
  zones                                = var.zones
  network                              = var.gcp_project_name
  subnetwork                           = "${var.env}-app-0"
  master_ipv4_cidr_block               = "10.0.0.0/28"
  ip_range_pods                        = var.cluster_secondary_range_name
  ip_range_services                    = var.services_secondary_range_name
  enable_private_endpoint              = false
  enable_private_nodes                 = true
  master_global_access_enabled         = true
  http_load_balancing                  = var.http_load_balancing
  horizontal_pod_autoscaling           = var.horizontal_pod_autoscaling
  enable_vertical_pod_autoscaling      = var.enable_vertical_pod_autoscaling
  config_connector                     = false
  network_policy                       = var.network_policy
  filestore_csi_driver                 = var.filestore_csi_driver
  enable_shielded_nodes                = var.enable_shielded_nodes
  istio                                = false
  istio_auth                           = "AUTH_MUTUAL_TLS"
  kalm_config                          = false
  gke_backup_agent_config              = var.gke_backup_agent_config
  create_service_account               = false
  default_max_pods_per_node            = var.default_max_pods_per_node
  identity_namespace                   = var.identity_namespace
  logging_service                      = var.logging_service
  monitoring_service                   = var.monitoring_service
  monitoring_enabled_components        = ["SYSTEM_COMPONENTS"]
  monitoring_enable_managed_prometheus = false
  node_metadata                        = var.node_metadata
  enable_binary_authorization          = var.enable_binary_authorization
  enable_cost_allocation               = var.enable_cost_allocation
  enable_mesh_certificates             = false
  release_channel                      = var.release_channel
  dns_cache                            = var.dns_cache
  resource_usage_export_dataset_id     = "all_billing_data"
  enable_network_egress_export         = var.enable_network_egress_export
  remove_default_node_pool             = true
  security_posture_mode                = "BASIC"
  security_posture_vulnerability_mode  = "VULNERABILITY_BASIC"
  workload_config_audit_mode           = "BASIC"
  workload_vulnerability_mode          = "BASIC"
  notification_config_topic            = "projects/${data.google_project.project.project_id}/topics/gke-cluster-upgrade-notification"
  deletion_protection                  = false

  cluster_autoscaling = {
    enabled             = false
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
    auto_repair         = true,
    auto_upgrade        = true,
    disk_size           = 0,
    disk_type           = "pd-standard",
    gpu_resources       = [],
    min_cpu_cores       = 0,
    max_cpu_cores       = 0,
    min_memory_gb       = 0,
    max_memory_gb       = 0
  }

  node_pools = [
    {
      name               = "kube-system-pool"
      machine_type       = var.machine_type
      node_locations     = var.node_locations
      min_count          = null
      max_count          = null
      total_min_count    = var.total_min_count
      total_max_count    = var.total_max_count
      location_policy    = "ANY"
      local_ssd_count    = var.local_ssd_count
      spot               = var.spot
      disk_size_gb       = var.disk_size_gb
      disk_type          = var.disk_type
      image_type         = var.image_type
      enable_gcfs        = var.enable_gcfs
      enable_gvnic       = var.enable_gvnic
      auto_repair        = var.auto_repair
      auto_upgrade       = var.auto_upgrade
      autoscaling        = var.autoscaling
      strategy           = var.strategy
      max_surge          = var.max_surge
      max_unavailable    = var.max_unavailable
      service_account    = data.google_compute_default_service_account.default.email
      preemptible        = var.preemptible
      initial_node_count = var.initial_node_count
    },
    {
      name               = "app-pool"
      machine_type       = var.machine_type
      node_locations     = var.node_locations
      min_count          = null
      max_count          = null
      total_min_count    = var.total_min_count
      total_max_count    = var.total_max_count
      location_policy    = "ANY"
      local_ssd_count    = var.local_ssd_count
      spot               = var.spot
      disk_size_gb       = var.disk_size_gb
      disk_type          = var.disk_type
      image_type         = var.image_type
      enable_gcfs        = var.enable_gcfs
      enable_gvnic       = var.enable_gvnic
      auto_repair        = var.auto_repair
      auto_upgrade       = var.auto_upgrade
      autoscaling        = var.autoscaling
      strategy           = var.strategy
      max_surge          = var.max_surge
      max_unavailable    = var.max_unavailable
      service_account    = data.google_compute_default_service_account.default.email
      preemptible        = var.preemptible
      initial_node_count = var.initial_node_count
    }
  ]

  node_pools_oauth_scopes = {
    all = []

    kube-system-pool = var.oauth_scopes
    app-pool         = var.oauth_scopes
  }

  node_pools_labels = {
    all = {}

    app-pool = {
      app = "little-quest-server"
    }
  }

  node_pools_metadata = {
    all = {}
  }

  node_pools_taints = {
    all = []

    app-pool = [
      {
        key    = "app"
        value  = "little-quest-server"
        effect = "NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    app-pool = [
      "little-quest-server",
    ]
  }
}

## Network
resource "google_compute_global_address" "little_quest_server_ip" {
  project       = data.google_project.project.project_id
  name          = "little-quest-server-ip"
  address_type  = "EXTERNAL"
  ip_version    = "IPV4"
  prefix_length = 0
}

resource "google_dns_record_set" "little_quest" {
  project      = data.google_project.project.project_id
  managed_zone = "${var.gcp_project_name}-demo"

  name = "little-quest-server.${var.gcp_project_name}.demo.altostrat.com."
  type = "A"
  ttl  = 60

  rrdatas = [google_compute_global_address.little_quest_server_ip.address]

  depends_on = [google_compute_global_address.little_quest_server_ip]
}

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
    "${data.google_project.project.project_id}=>roles/cloudtrace.agent",
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
