module "corp-0" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.gcp_project_id
  name                       = "corp-0"
  regional                   = true
  region                     = var.region
  zones                      = var.zones
  network                    = var.gcp_project_name
  subnetwork                 = "corp-0"
  ip_range_pods              = var.cluster_secondary_range_name
  ip_range_services          = var.services_secondary_range_name
  http_load_balancing        = var.http_load_balancing
  horizontal_pod_autoscaling = var.horizontal_pod_autoscaling
  network_policy             = var.network_policy
  create_service_account     = false
  default_max_pods_per_node  = var.default_max_pods_per_node
  identity_namespace         = var.identity_namespace
  logging_service            = var.logging_service
  monitoring_service         = var.monitoring_service
  node_metadata              = var.node_metadata
  release_channel            = var.release_channel
  remove_default_node_pool   = true

  node_pools = [
    {
      name               = "default-pool"
      machine_type       = var.machine_type
      node_locations     = var.node_locations
      min_count          = var.min_count
      max_count          = var.max_count
      local_ssd_count    = var.local_ssd_count
      disk_size_gb       = var.disk_size_gb
      disk_type          = var.disk_type
      image_type         = var.image_type
      auto_repair        = var.auto_repair
      auto_upgrade       = var.auto_upgrade
      autoscaling        = var.autoscaling
      service_account    = var.service_account
      preemptible        = var.preemptible
      initial_node_count = var.initial_node_count
    }
  ]

  node_pools_oauth_scopes = {
    all = []

    default-pool = var.oauth_scopes
  }

  node_pools_labels = {
    all = {}
  }

  node_pools_metadata = {
    all = {}
  }

  node_pools_taints = {
    all = []
  }

  node_pools_tags = {
    all = []

    default-pool = [
      "default-pool",
    ]
  }

}
