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
  version                              = "36.3.0"
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
  default_max_pods_per_node            = 40
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
  security_posture_mode                = "DISABLED"
  security_posture_vulnerability_mode  = "VULNERABILITY_DISABLED"
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
      name                    = "kube-system-pool"
      machine_type            = "t2d-standard-2"
      node_locations          = var.node_locations
      min_count               = null
      max_count               = null
      total_min_count         = 2 # kube-system has kube-dns which may be SPOF, so 2 instances contributes to reliablity
      total_max_count         = var.total_max_count
      location_policy         = "ANY"
      local_ssd_count         = var.local_ssd_count
      spot                    = var.spot
      disk_size_gb            = var.disk_size_gb
      disk_type               = var.disk_type
      image_type              = var.image_type
      enable_gcfs             = var.enable_gcfs
      enable_gvnic            = var.enable_gvnic
      auto_repair             = var.auto_repair
      auto_upgrade            = var.auto_upgrade
      strategy                = "BLUE_GREEN"
      node_pool_soak_duration = "1800s"
      batch_node_count        = 1
      batch_soak_duration     = "180s"
      service_account         = data.google_compute_default_service_account.default.email
      preemptible             = var.preemptible
      initial_node_count      = var.initial_node_count
    },
    {
      name                    = "open-match-pool"
      machine_type            = "t2d-standard-2"
      node_locations          = var.node_locations
      min_count               = null
      max_count               = null
      total_min_count         = 2
      total_max_count         = var.total_max_count
      location_policy         = "ANY"
      local_ssd_count         = var.local_ssd_count
      spot                    = var.spot
      disk_size_gb            = var.disk_size_gb
      disk_type               = var.disk_type
      image_type              = var.image_type
      enable_gcfs             = var.enable_gcfs
      enable_gvnic            = var.enable_gvnic
      auto_repair             = var.auto_repair
      auto_upgrade            = var.auto_upgrade
      strategy                = "BLUE_GREEN"
      node_pool_soak_duration = "1800s"
      batch_node_count        = 1
      batch_soak_duration     = "180s"
      service_account         = data.google_compute_default_service_account.default.email
      preemptible             = var.preemptible
      initial_node_count      = var.initial_node_count
    },
    {
      name                    = "agones-gameserver-pool"
      machine_type            = "t2d-standard-2"
      node_locations          = var.node_locations
      min_count               = null
      max_count               = null
      total_min_count         = var.total_min_count
      total_max_count         = var.total_max_count
      location_policy         = "ANY"
      local_ssd_count         = var.local_ssd_count
      spot                    = var.spot
      disk_size_gb            = var.disk_size_gb
      disk_type               = var.disk_type
      image_type              = var.image_type
      enable_gcfs             = var.enable_gcfs
      enable_gvnic            = var.enable_gvnic
      auto_repair             = var.auto_repair
      auto_upgrade            = var.auto_upgrade
      strategy                = "BLUE_GREEN"
      node_pool_soak_duration = "3600s"
      batch_node_count        = 1
      batch_soak_duration     = "600s"
      service_account         = data.google_compute_default_service_account.default.email
      preemptible             = var.preemptible
      initial_node_count      = var.initial_node_count
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

resource "google_secret_manager_secret" "gke_corp_0_clustername" {
  project   = data.google_project.project.project_id
  secret_id = "gke_corp_0_clustername"

  labels = {
    role = "gke_corp_0_clustername"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret_version" "gke_corp_0_clustername" {
  secret = google_secret_manager_secret.gke_corp_0_clustername.id

  secret_data = "corp-0"

  depends_on = [module.corp-0, google_secret_manager_secret.gke_corp_0_clustername]
}

resource "google_secret_manager_secret" "gke_corp_0_endpoint" {
  project   = data.google_project.project.project_id
  secret_id = "gke_corp_0_endpoint"

  labels = {
    role = "gke_corp_0_endpoint"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret_version" "gke_corp_0_endpoint" {
  secret = google_secret_manager_secret.gke_corp_0_endpoint.id

  secret_data = "https://${module.corp-0.endpoint}"

  depends_on = [module.corp-0, google_secret_manager_secret.gke_corp_0_endpoint]
}

resource "google_secret_manager_secret" "gke_corp_0_clusterconfig" {
  project   = data.google_project.project.project_id
  secret_id = "gke_corp_0_clusterconfig"

  labels = {
    role = "gke_corp_0_clusterconfig"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret_version" "gke_corp_0_clusterconfig" {
  secret = google_secret_manager_secret.gke_corp_0_clusterconfig.id

  secret_data = <<EOF
{
  "execProviderConfig": {
    "command": "argocd-k8s-auth",
    "args": ["gcp"],
    "apiVersion": "client.authentication.k8s.io/v1beta1"
  },
  "tlsClientConfig": {
    "insecure": false,
    "caData": "${module.corp-0.ca_certificate}"
  }
}
EOF


  depends_on = [module.corp-0, google_secret_manager_secret.gke_corp_0_clusterconfig]
}

data "google_client_config" "default" {}

provider "kubernetes" {
  alias                  = "corp0"
  host                   = "https://${module.corp-0.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.corp-0.ca_certificate)

  ignore_annotations = [
    "^cloud\\.google\\.com\\/.*"
  ]
}

resource "kubernetes_namespace" "corp0_corp_0" {
  provider = kubernetes.corp0

  metadata {
    name = "corp-0"
    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [module.corp-0]
}

resource "kubernetes_service_account" "corp0_little_quest_realtime" {
  provider = kubernetes.corp0

  metadata {
    name      = "little-quest-realtime"
    namespace = "corp-0"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "little-quest-realtime"
      "meta.helm.sh/release-namespace" = "corp-0"
    }
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.corp0_corp_0]
}

resource "kubernetes_service_account" "corp0_little_quest_frontend" {
  provider = kubernetes.corp0

  metadata {
    name      = "little-quest-frontend"
    namespace = "corp-0"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "little-quest-realtime"
      "meta.helm.sh/release-namespace" = "corp-0"
    }
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.corp0_corp_0]
}

resource "kubernetes_service_account" "corp0_little_quest_mmf" {
  provider = kubernetes.corp0

  metadata {
    name      = "little-quest-mmf"
    namespace = "corp-0"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "little-quest-realtime"
      "meta.helm.sh/release-namespace" = "corp-0"
    }
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.corp0_corp_0]
}

resource "kubernetes_service_account" "corp0_little_quest_director" {
  provider = kubernetes.corp0

  metadata {
    name      = "little-quest-director"
    namespace = "corp-0"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "little-quest-realtime"
      "meta.helm.sh/release-namespace" = "corp-0"
    }
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.corp0_corp_0]
}

resource "kubernetes_namespace" "corp0_agones_system" {
  provider = kubernetes.corp0

  metadata {
    name = "agones-system"
    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [module.corp-0]
}

resource "kubernetes_service_account" "corp0_agones_allocator" {
  provider = kubernetes.corp0

  metadata {
    name      = "agones-allocator"
    namespace = "agones-system"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "agones"
      "meta.helm.sh/release-namespace" = "agones-system"
    }
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.corp0_agones_system]
}

resource "kubernetes_service_account" "corp0_agones_controller" {
  provider = kubernetes.corp0

  metadata {
    name      = "agones-controller"
    namespace = "agones-system"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "agones"
      "meta.helm.sh/release-namespace" = "agones-system"
    }
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.corp0_agones_system]
}

resource "kubernetes_namespace" "corp0_open_match" {
  provider = kubernetes.corp0

  metadata {
    name = "open-match"
    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [module.corp-0]
}

resource "kubernetes_service_account" "corp0_open_match_service" {
  provider = kubernetes.corp0

  metadata {
    name      = "open-match-service"
    namespace = "open-match"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "open-match"
      "meta.helm.sh/release-namespace" = "open-match"
    }
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.corp0_open_match]
}

