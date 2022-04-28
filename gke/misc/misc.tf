module "misc-0" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                 = var.gcp_project_id
  name                       = "misc-0"
  regional                   = true
  region                     = var.region
  zones                      = var.zones
  network                    = var.gcp_project_name
  subnetwork                 = "misc-0"
  master_ipv4_cidr_block     = "11.0.0.0/28"
  ip_range_pods              = var.cluster_secondary_range_name
  ip_range_services          = var.services_secondary_range_name
  enable_private_endpoint    = false
  enable_private_nodes       = true
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
      name               = "kube-system-pool"
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
    },
    {
      name               = "argocd-pool"
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
    },
    {
      name               = "prometheus-pool"
      machine_type       = "n2-highmem-2"
      node_locations     = "asia-northeast1-a"
      min_count          = var.min_count
      max_count          = 1
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

    kube-system-pool = var.oauth_scopes
    argocd-pool      = var.oauth_scopes
    prometheus-pool  = var.oauth_scopes
  }

  node_pools_labels = {
    all = {}

    argocd-pool = {
      app = "argocd"
    }

    prometheus-pool = {
      app = "prometheus"
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

    prometheus-pool = [
      {
        key    = "app"
        value  = "prometheus"
        effect = "NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    argocd-pool = [
      "argocd",
    ]

    prometheus-pool = [
      "prometheus",
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
    "misc-0-prometheus-ip"
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

resource "google_dns_record_set" "prometheus" {
  project      = var.gcp_project_id
  managed_zone = "${var.gcp_project_name}-org"

  name = "misc-0-prometheus.kentaiso.org."
  type = "A"
  ttl  = 60

  rrdatas = [module.gke_workload_address.addresses[1]]

  depends_on = [module.gke_workload_address]
}

## Secret
resource "google_secret_manager_secret" "client_id" {
  project   = var.gcp_project_id
  secret_id = "client_id"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "client_secret" {
  project   = var.gcp_project_id
  secret_id = "client_secret"

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
}

module "argocd_secretmanager" {
  source  = "terraform-google-modules/iam/google//modules/secret_manager_iam"
  project = var.gcp_project_id
  secrets = ["client_id", "client_secret"]
  mode    = "additive"

  bindings = {
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:${module.argocd_secretmanager_sa.service_account.email}"
    ]
  }

  depends_on = [module.argocd_secretmanager_sa]
}
