data "google_project" "project" {
}

data "google_compute_default_service_account" "default" {
}

data "google_compute_network" "vpc_network" {
  project = data.google_project.project.project_id
  name    = var.gcp_project_name
}

module "corp-0" {
  source                               = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster"
  version                              = "29.0.0"
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
  monitoring_enabled_components        = ["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER"]
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

    kube-system-pool       = var.oauth_scopes
    open-match-pool        = var.oauth_scopes
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

module "little_quest_realtime_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names        = ["little-quest-realtime"]
  display_name = "Little Quest Realtime ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/cloudprofiler.agent",
  ]
}

module "little_quest_realtime_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  service_accounts = [module.little_quest_realtime_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[corp-0/little-quest-realtime]"
    ]
  }
  depends_on = [module.little_quest_realtime_sa]
}

module "little_quest_frontend_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names        = ["little-quest-frontend"]
  display_name = "Little Quest Frontend ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/cloudprofiler.agent",
    "${data.google_project.project.project_id}=>roles/cloudtrace.agent",
  ]
}

module "little_quest_frontend_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  service_accounts = [module.little_quest_frontend_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[corp-0/little-quest-frontend]"
    ]
  }
  depends_on = [module.little_quest_frontend_sa]
}

module "little_quest_mmf_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names        = ["little-quest-mmf"]
  display_name = "Little Quest Match Function ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/cloudprofiler.agent",
    "${data.google_project.project.project_id}=>roles/cloudtrace.agent",
  ]
}

module "little_quest_mmf_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  service_accounts = [module.little_quest_mmf_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[corp-0/little-quest-mmf]"
    ]
  }
  depends_on = [module.little_quest_mmf_sa]
}

module "little_quest_director_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names        = ["little-quest-director"]
  display_name = "Little Quest Director ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/cloudprofiler.agent",
    "${data.google_project.project.project_id}=>roles/cloudtrace.agent",
  ]
}

module "little_quest_director_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  service_accounts = [module.little_quest_director_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[corp-0/little-quest-director]"
    ]
  }
  depends_on = [module.little_quest_director_sa]
}

module "agones_allocator_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names         = ["agones-allocator"]
  display_name  = "Agones Allocator ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/monitoring.metricWriter"]
}

module "agones_allocator_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
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
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names         = ["agones-controller"]
  display_name  = "Agones Controller ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/monitoring.metricWriter"]
}

module "agones_controller_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
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

module "openmatch_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names        = ["open-match-service"]
  display_name = "Open Match ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/monitoring.metricWriter",
    "${data.google_project.project.project_id}=>roles/cloudtrace.agent",
  ]
}

module "openmatch_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  service_accounts = [module.openmatch_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[open-match/open-match-service]"
    ]
  }
  depends_on = [module.openmatch_sa]
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

