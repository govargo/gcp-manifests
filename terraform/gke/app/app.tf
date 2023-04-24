module "app-0" {
  source                       = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                      = "25.0.0"
  project_id                   = var.gcp_project_id
  name                         = "app-0"
  regional                     = true
  region                       = var.region
  zones                        = var.zones
  network                      = var.gcp_project_name
  subnetwork                   = "app-0"
  master_ipv4_cidr_block       = "10.0.0.0/28"
  ip_range_pods                = var.cluster_secondary_range_name
  ip_range_services            = var.services_secondary_range_name
  enable_private_endpoint      = false
  enable_private_nodes         = true
  master_global_access_enabled = true
  http_load_balancing          = var.http_load_balancing
  horizontal_pod_autoscaling   = var.horizontal_pod_autoscaling
  network_policy               = var.network_policy
  filestore_csi_driver         = var.filestore_csi_driver
  enable_shielded_nodes        = var.enable_shielded_nodes
  gke_backup_agent_config      = var.gke_backup_agent_config
  create_service_account       = false
  default_max_pods_per_node    = var.default_max_pods_per_node
  identity_namespace           = var.identity_namespace
  logging_service              = var.logging_service
  monitoring_service           = var.monitoring_service
  node_metadata                = var.node_metadata
  release_channel              = var.release_channel
  remove_default_node_pool     = true

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
      service_account    = var.service_account
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
      service_account    = var.service_account
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
      app = "little"
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
        value  = "little"
        effect = "NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    app-pool = [
      "little",
    ]
  }
}

## Cloud Pub/Sub Topic
resource "google_pubsub_topic" "production-realtime-data-analytics" {
  project = var.gcp_project_id
  name    = "${var.env}-realtime-data-analytics"

  labels = {
    env  = "production",
    case = "realtime-data-analytics"
  }

  message_retention_duration = "86600s"
}

