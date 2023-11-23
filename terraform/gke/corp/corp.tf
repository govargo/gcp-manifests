data "google_project" "project" {
}

data "google_compute_default_service_account" "default" {
}

data "google_compute_network" "vpc_network" {
  project = data.google_project.project.project_id
  name    = var.gcp_project_name
}

module "corp-0" {
  source                               = "terraform-google-modules/kubernetes-engine/google"
  version                              = "25.0.0"
  project_id                           = data.google_project.project.project_id
  name                                 = "${var.env}-corp-0"
  regional                             = true
  region                               = var.region
  zones                                = var.zones
  network                              = var.gcp_project_name
  subnetwork                           = "${var.env}-corp-0"
  ip_range_pods                        = var.cluster_secondary_range_name
  ip_range_services                    = var.services_secondary_range_name
  http_load_balancing                  = var.http_load_balancing
  horizontal_pod_autoscaling           = var.horizontal_pod_autoscaling
  enable_vertical_pod_autoscaling      = var.enable_vertical_pod_autoscaling
  network_policy                       = var.network_policy
  filestore_csi_driver                 = var.filestore_csi_driver
  enable_shielded_nodes                = var.enable_shielded_nodes
  gke_backup_agent_config              = var.gke_backup_agent_config
  create_service_account               = false
  default_max_pods_per_node            = var.default_max_pods_per_node
  identity_namespace                   = var.identity_namespace
  logging_service                      = var.logging_service
  monitoring_service                   = var.monitoring_service
  monitoring_enabled_components        = ["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER"]
  monitoring_enable_managed_prometheus = false
  node_metadata                        = var.node_metadata
  enable_binary_authorization          = var.enable_binary_authorization
  enable_cost_allocation               = var.enable_cost_allocation
  release_channel                      = var.release_channel
  dns_cache                            = var.dns_cache
  resource_usage_export_dataset_id     = "all_billing_data"
  enable_network_egress_export         = var.enable_network_egress_export
  remove_default_node_pool             = true
  notification_config_topic            = "projects/${data.google_project.project.project_id}/topics/gke-cluster-upgrade-notification"

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
      name               = "open-match-pool"
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
      name               = "agones-gameserver-pool"
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
    open-match-pool  = var.oauth_scopes
    agones-gameserver-pool = var.oauth_scopes
  }

  node_pools_labels = {
    all = {}

    open-match-pool = {
      app = "open-match"
    }

    agones-gameserver-pool = {
      app = "agones-gameserver"
    }
  }

  node_pools_metadata = {
    all = {}
  }

  node_pools_taints = {
    all = []

    open-match-pool = [
      {
        key    = "app"
        value  = "open-match"
        effect = "NO_SCHEDULE"
      },
    ]

    agones-gameserver-pool = [
      {
        key    = "app"
        value  = "agones-gameserver"
        effect = "NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    open-match-pool = [
      "open-match",
    ]

    agones-gameserver-pool = [
      "agones-gameserver",
    ]
  }
}

module "agones_allocator_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.1.1"
  project_id = data.google_project.project.project_id

  names         = ["agones-allocator"]
  display_name  = "Agones Allocator ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/monitoring.metricWriter"]
}

module "agones_allocator_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.4.0"
  project = data.google_project.project.project_id

  service_accounts = [module.agones_allocator_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[agones-system/agones-allocator]"
    ]
  }
  depends_on = [module.agones_allocator_sa]
}

module "agones_controller_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.1.1"
  project_id = data.google_project.project.project_id

  names         = ["agones-controller"]
  display_name  = "Agones Controller ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/monitoring.metricWriter"]
}

module "agones_controller_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.4.0"
  project = data.google_project.project.project_id

  service_accounts = [module.agones_controller_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[agones-system/agones-controller]"
    ]
  }
  depends_on = [module.agones_controller_sa]
}

resource "google_compute_address" "agones_allocator_internal_address" {
  project = data.google_project.project.project_id

  name         = "agones-allocator-internal-address"
  subnetwork   = "${var.env}-corp-0"
  address_type = "INTERNAL"
  address      = "10.130.0.54"
  region       = var.region
}

resource "google_dns_record_set" "agones_allocator" {
  project      = data.google_project.project.project_id
  managed_zone = "${var.gcp_project_name}-demo"

  name = "agones.allocator.${var.gcp_project_name}.demo.altostrat.com."
  type = "A"
  ttl  = 60

  rrdatas = [google_compute_address.agones_allocator_internal_address.address]

  depends_on = [google_compute_address.agones_allocator_internal_address]
}

resource "google_compute_firewall" "allow_agones_gameserver_ingress" {
  project = data.google_project.project.project_id

  name        = "allow-agones-gameserver-ingress"
  network     = data.google_compute_network.vpc_network.id
  description = "Allow Game Client -> Agones GameServer"

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["7000-8000"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["gke-${var.env}-corp-0-agones-gameserver-pool"]
}
