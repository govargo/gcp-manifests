data "google_project" "project" {
}

data "google_compute_default_service_account" "default" {
}

module "misc-0" {
  source                               = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                              = "29.0.0"
  project_id                           = data.google_project.project.project_id
  name                                 = "${var.env}-misc-0"
  regional                             = false
  zones                                = var.zones
  network                              = var.gcp_project_name
  subnetwork                           = "${var.env}-misc-0"
  master_ipv4_cidr_block               = "11.0.0.0/28"
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
  notification_config_topic            = "projects/${data.google_project.project.project_id}/topics/gke-cluster-upgrade-notification"

  node_pools = [
    {
      name               = "kube-system-pool"
      machine_type       = var.machine_type
      node_locations     = var.node_locations
      min_count          = null
      max_count          = null
      total_min_count    = var.total_min_count
      total_max_count    = 1
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
      name               = "argocd-pool"
      machine_type       = var.machine_type
      node_locations     = var.node_locations
      min_count          = null
      max_count          = null
      total_min_count    = var.total_min_count
      total_max_count    = 1
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
resource "google_compute_global_address" "argocd_server_ip" {
  project       = data.google_project.project.project_id
  name          = "argocd-server-ip"
  address_type  = "EXTERNAL"
  ip_version    = "IPV4"
  prefix_length = 0
}

resource "google_dns_record_set" "argocd_server" {
  project      = data.google_project.project.project_id
  managed_zone = "${var.gcp_project_name}-demo"

  name = "argocd.${var.gcp_project_name}.demo.altostrat.com."
  type = "A"
  ttl  = 60

  rrdatas = [google_compute_global_address.argocd_server_ip.address]

  depends_on = [google_compute_global_address.argocd_server_ip]
}

## Secret
resource "google_secret_manager_secret" "argocd_client_id" {
  project   = data.google_project.project.project_id
  secret_id = "argocd_client_id"

  labels = {
    role = "argocd_client_id"
  }

  lifecycle {
    prevent_destroy = true
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "argocd_client_secret" {
  project   = data.google_project.project.project_id
  secret_id = "argocd_client_secret"

  labels = {
    role = "argocd_client_secret"
  }

  lifecycle {
    prevent_destroy = true
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "argocd_notification_webhook_url" {
  project   = data.google_project.project.project_id
  secret_id = "argocd_notification_webhook_url"

  labels = {
    role = "argocd_notification_webhook_url"
  }

  lifecycle {
    prevent_destroy = true
  }

  replication {
    auto {}
  }
}

## ServiceAccount
module "argocd_dex_server_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names        = ["argocd-dex-server"]
  display_name = "ArgoCD Dex Server ServiceAccount"
}

module "argocd_dex_server_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  service_accounts = [module.argocd_dex_server_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[argocd/argocd-dex-server]"
    ]
  }

  depends_on = [module.argocd_dex_server_sa]
}

module "argocd_dex_server_secret_accessor_binding" {
  source  = "terraform-google-modules/iam/google//modules/secret_manager_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  secrets = ["argocd_client_id", "argocd_client_secret"]
  mode    = "authoritative"

  bindings = {
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:${module.argocd_dex_server_sa.service_account.email}"
    ]
  }

  depends_on = [
    module.argocd_dex_server_sa,
    google_secret_manager_secret.argocd_client_id,
    google_secret_manager_secret.argocd_client_secret
  ]
}

module "argocd_repo_server_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names         = ["argocd-repo-server"]
  display_name  = "ArgoCD Repo server ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/artifactregistry.reader"]
}

module "argocd_repo_server_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  service_accounts = [module.argocd_repo_server_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[argocd/argocd-repo-server]"
    ]
  }

  depends_on = [module.argocd_repo_server_sa]
}

module "argocd_notifications_controller_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names        = ["argocd-notifications"]
  display_name = "ArgoCD Notifications Controller ServiceAccount"
}

module "argocd_notifications_controller_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  service_accounts = [module.argocd_notifications_controller_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[argocd/argocd-notifications]"
    ]
  }

  depends_on = [module.argocd_notifications_controller_sa]
}

module "argocd_notifications_controller_secret_accessor_binding" {
  source  = "terraform-google-modules/iam/google//modules/secret_manager_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  secrets = [google_secret_manager_secret.argocd_notification_webhook_url.secret_id]
  mode    = "additive"
  bindings = {
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:${module.argocd_notifications_controller_sa.email}"
    ]
  }
  depends_on = [module.argocd_notifications_controller_sa, google_secret_manager_secret.argocd_notification_webhook_url]
}

module "gmp_collector_sa" {
  source       = "terraform-google-modules/service-accounts/google"
  version      = "4.2.2"
  project_id   = data.google_project.project.project_id
  names        = ["collector"]
  display_name = "Google Managed Prometheus Collector ServiceAccount"
}

module "gmp_collector_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  service_accounts = [module.gmp_collector_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[gmp-system/collector]"
    ]
  }
  depends_on = [module.gmp_collector_sa]
}

module "gmp_collector_monitoring_writer_binding" {
  source     = "terraform-google-modules/iam/google//modules/member_iam"
  version    = "7.7.1"
  project_id = data.google_project.project.project_id

  service_account_address = "collector@${data.google_project.project.project_id}.iam.gserviceaccount.com"
  prefix                  = "serviceAccount"
  project_roles           = ["roles/monitoring.metricWriter"]

  depends_on = [module.gmp_collector_sa]
}

resource "google_project_iam_custom_role" "gmp_rule_evaluator_role" {
  role_id     = "ruleevaluator"
  title       = "GMP Rule Evaluator"
  description = "GMP Rule Evaluator Monitoring role"
  permissions = ["monitoring.timeSeries.create", "monitoring.timeSeries.list"]
  stage       = "GA"
}

module "gmp_ruleevaluator_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names        = ["rule-evaluator"]
  display_name = "Google Managed Prometheus Rule-Evaluator ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/monitoring.viewer",
    "${data.google_project.project.project_id}=>projects/${data.google_project.project.project_id}/roles/${google_project_iam_custom_role.gmp_rule_evaluator_role.role_id}",
  ]
  depends_on = [google_project_iam_custom_role.gmp_rule_evaluator_role]
}

module "gmp_ruleevaluator_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  service_accounts = [module.gmp_ruleevaluator_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[gmp-system/rule-evaluator]"
    ]
  }
  depends_on = [module.gmp_ruleevaluator_sa]
}

module "argocd_image_updater_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.2"
  project_id = data.google_project.project.project_id

  names         = ["argocd-image-updater"]
  display_name  = "ArgoCD image updater ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/artifactregistry.reader"]
  depends_on    = [google_project_iam_custom_role.gmp_rule_evaluator_role]
}

module "argocd_image_updater_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "7.7.1"
  project = data.google_project.project.project_id

  service_accounts = [module.argocd_image_updater_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[argocd/argocd-image-updater]"
    ]
  }
  depends_on = [module.argocd_image_updater_sa]
}
