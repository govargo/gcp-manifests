data "google_project" "project" {
}

data "google_compute_default_service_account" "default" {
}

module "misc-0" {
  source                               = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version                              = "34.0.0"
  project_id                           = data.google_project.project.project_id
  name                                 = "${var.env}-misc-0"
  regional                             = false
  zones                                = var.zones
  network                              = var.gcp_project_name
  subnetwork                           = "${var.env}-misc-0"
  master_ipv4_cidr_block               = "10.2.0.0/28"
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
  istio                                = false
  istio_auth                           = "AUTH_MUTUAL_TLS"
  kalm_config                          = false
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
      machine_type       = "t2d-standard-2"
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
      machine_type       = "t2d-standard-2"
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

data "google_client_config" "default" {}

provider "kubernetes" {
  alias                  = "misc0"
  host                   = "https://${module.misc-0.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.misc-0.ca_certificate)

  ignore_annotations = [
    "^cloud\\.google\\.com\\/.*"
  ]
}

resource "kubernetes_namespace" "misc0_argocd" {
  provider = kubernetes.misc0

  metadata {
    name = "argocd"
  }

  depends_on = [module.misc-0]
}

resource "kubernetes_service_account" "misc0_argocd_server" {
  provider = kubernetes.misc0

  metadata {
    name      = "argocd-server"
    namespace = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "argocd"
      "meta.helm.sh/release-namespace" = "argocd"
    }
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.misc0_argocd]
}

resource "kubernetes_service_account" "misc0_argocd_application_controller" {
  provider = kubernetes.misc0

  metadata {
    name      = "argocd-application-controller"
    namespace = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "argocd"
      "meta.helm.sh/release-namespace" = "argocd"
    }
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.misc0_argocd]
}

resource "kubernetes_service_account" "misc0_argocd_dex_server" {
  provider = kubernetes.misc0

  metadata {
    name      = "argocd-dex-server"
    namespace = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "argocd"
      "meta.helm.sh/release-namespace" = "argocd"
    }
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.misc0_argocd]
}

resource "kubernetes_service_account" "misc0_argocd_repo_server" {
  provider = kubernetes.misc0

  metadata {
    name      = "argocd-repo-server"
    namespace = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "argocd"
      "meta.helm.sh/release-namespace" = "argocd"
    }
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.misc0_argocd]
}

resource "kubernetes_service_account" "misc0_argocd_argocd_notifications" {
  provider = kubernetes.misc0

  metadata {
    name      = "argocd-notifications"
    namespace = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "argocd"
      "meta.helm.sh/release-namespace" = "argocd"
    }
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.misc0_argocd]
}

resource "kubernetes_service_account" "misc0_argocd_argocd_image_updater" {
  provider = kubernetes.misc0

  metadata {
    name      = "argocd-image-updater"
    namespace = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "argocd"
      "meta.helm.sh/release-namespace" = "argocd"
    }
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.misc0_argocd]
}

resource "kubernetes_namespace" "misc0_gmp_system" {
  provider = kubernetes.misc0

  metadata {
    name = "gmp-system"
  }

  depends_on = [module.misc-0]
}

resource "kubernetes_service_account" "misc0_gmp_collector" {
  provider = kubernetes.misc0

  metadata {
    name      = "collector"
    namespace = "gmp-system"
  }

  lifecycle {
    ignore_changes = [metadata["labels"], metadata["annotations"]]
  }
  depends_on = [kubernetes_namespace.misc0_argocd]
}
