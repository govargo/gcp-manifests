module "misc-0" {
  source                       = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                      = "25.0.0"
  project_id                   = var.gcp_project_id
  name                         = "${var.env}-misc-0"
  regional                     = true
  region                       = var.region
  zones                        = var.zones
  network                      = var.gcp_project_name
  subnetwork                   = "${var.env}-misc-0"
  master_ipv4_cidr_block       = "11.0.0.0/28"
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
      name               = "argocd-pool"
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
    argocd-pool      = var.oauth_scopes
  }

  node_pools_labels = {
    all = {}

    argocd-pool = {
      app = "argocd"
    }
  }

  node_pools_metadata = {
    all = {}
  }

  node_pools_taints = {
    all = []

    argocd-pool = [
      {
        key    = "app"
        value  = "argocd"
        effect = "NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    argocd-pool = [
      "argocd",
    ]
  }

}

## Network
module "gke_workload_address" {
  source       = "terraform-google-modules/address/google"
  version      = "3.1.1"
  project_id   = var.gcp_project_id
  region       = var.region
  address_type = "EXTERNAL"
  global       = true
  names = [
    "argocd-ip",
  ]
}

resource "google_dns_record_set" "argocd" {
  project      = var.gcp_project_id
  managed_zone = "${var.gcp_project_name}-org"

  name = "argocd.kentaiso.org."
  type = "A"
  ttl  = 60

  rrdatas = [module.gke_workload_address.addresses[0]]

  depends_on = [module.gke_workload_address]
}

## Secret
resource "google_secret_manager_secret" "argocd_client_id" {
  project   = var.gcp_project_id
  secret_id = "argocd_client_id"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "argocd_client_secret" {
  project   = var.gcp_project_id
  secret_id = "argocd_client_secret"

  replication {
    automatic = true
  }
}

## ServiceAccount
module "argocd_secretmanager_sa" {
  source       = "terraform-google-modules/service-accounts/google"
  version      = "4.1.1"
  project_id   = var.gcp_project_id
  names        = ["argocd-dex-server"]
  display_name = "ArgoCD SecretManager ServiceAccount"
}

module "argocd_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.4.0"

  service_accounts = [module.argocd_secretmanager_sa.email]
  project          = var.gcp_project_id
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${var.gcp_project_id}.svc.id.goog[argocd/argocd-dex-server]"
    ]
  }

  depends_on = [module.argocd_secretmanager_sa]
}

module "argocd_secretmanager" {
  source  = "terraform-google-modules/iam/google//modules/secret_manager_iam"
  version = "7.4.1"

  project = var.gcp_project_id
  secrets = ["argocd_client_id", "argocd_client_secret"]
  mode    = "authoritative"

  bindings = {
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:${module.argocd_secretmanager_sa.service_account.email}"
    ]
  }

  depends_on = [
    module.argocd_secretmanager_sa,
    google_secret_manager_secret.argocd_client_id,
    google_secret_manager_secret.argocd_client_secret
  ]
}

module "gmp_collector_sa" {
  source       = "terraform-google-modules/service-accounts/google"
  version      = "4.1.1"
  project_id   = var.gcp_project_id
  names        = ["collector"]
  display_name = "Google Managed Prometheus Collector ServiceAccount"
}

module "gmp_collector_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.4.0"

  service_accounts = [module.gmp_collector_sa.email]
  project          = var.gcp_project_id
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${var.gcp_project_id}.svc.id.goog[gmp-system/collector]"
    ]
  }
  depends_on = [module.gmp_collector_sa]
}

module "gmp_collector_monitoring_writer_binding" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = "collector@${var.gcp_project_id}.iam.gserviceaccount.com"
  prefix                  = "serviceAccount"
  project_id              = var.gcp_project_id
  project_roles           = ["roles/monitoring.metricWriter"]

  depends_on = [module.gmp_collector_sa]
}

module "gmp_ruleevaluator_sa" {
  source       = "terraform-google-modules/service-accounts/google"
  version      = "4.1.1"
  project_id   = var.gcp_project_id
  names        = ["rule-evaluator"]
  display_name = "Google Managed Prometheus Rule-Evaluator ServiceAccount"
}

module "gmp_ruleevaluator_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.4.0"

  service_accounts = [module.gmp_ruleevaluator_sa.email]
  project          = var.gcp_project_id
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${var.gcp_project_id}.svc.id.goog[gmp-system/rule-evaluator]"
    ]
  }
  depends_on = [module.gmp_ruleevaluator_sa]
}

resource "google_project_iam_custom_role" "gmp_rule_evaluator_role" {
  role_id     = "ruleevaluator"
  title       = "GMP Rule Evaluator"
  description = "GMP Rule Evaluator Monitoring role"
  permissions = ["monitoring.timeSeries.create", "monitoring.timeSeries.list"]
  stage       = "GA"
}

resource "google_project_iam_member" "gmp_rule_evaluator_binding" {
  project = var.gcp_project_id
  role    = "projects/${var.gcp_project_id}/roles/${google_project_iam_custom_role.gmp_rule_evaluator_role.role_id}"

  member = "serviceAccount:${module.gmp_ruleevaluator_sa.email}"

  depends_on = [
    google_project_iam_custom_role.gmp_rule_evaluator_role,
    module.gmp_ruleevaluator_sa,
  ]
}
