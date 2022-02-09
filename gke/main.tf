resource "google_container_cluster" "app_0" {
  provider = google-beta

  name                        = "app-0"
  project                     = var.gcp_project_id
  network                     = "projects/${var.gcp_project_id}/global/networks/${var.gcp_project_name}"
  subnetwork                  = "projects/${var.gcp_project_id}/regions/${var.region}/subnetworks/${var.region}"
  location                    = var.location
  initial_node_count          = var.initial_node_count
  default_max_pods_per_node   = var.default_max_pods_per_node
  networking_mode             = var.networking_mode
  logging_service             = var.logging_service
  monitoring_service          = var.monitoring_service
  remove_default_node_pool    = var.remove_default_node_pool
  enable_binary_authorization = true
  enable_intranode_visibility = var.enable_intranode_visibility
  enable_kubernetes_alpha     = var.enable_kubernetes_alpha
  enable_legacy_abac          = var.enable_legacy_abac
  enable_shielded_nodes       = var.enable_shielded_nodes
  enable_tpu                  = var.enable_tpu

  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  addons_config {
    http_load_balancing {
      disabled = var.disabled_http_load_balancing
    }

    horizontal_pod_autoscaling {
      disabled = var.disabled_horizontal_pod_autoscaling
    }
  }

  cluster_autoscaling {
    enabled             = var.node_provisioning
    autoscaling_profile = var.autoscaling_profile
  }

  network_policy {
    enabled = var.network_policy
  }

  pod_security_policy_config {
    enabled = var.pod_security_policy_config
  }

  notification_config {
    pubsub {
      enabled = var.notification_config
    }
  }

  release_channel {
    channel = var.channel
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

}

resource "google_container_node_pool" "default" {

  provider = google-beta

  name              = "default-pool"
  project           = var.gcp_project_id
  location          = var.node_locations[0]
  cluster           = google_container_cluster.app_0.name
  node_count        = var.node_count
  max_pods_per_node = var.default_max_pods_per_node

  node_config {
    image_type       = var.image_type
    machine_type     = var.machine_type
    disk_type        = var.disk_type
    disk_size_gb     = var.disk_size_gb
    min_cpu_platform = var.min_cpu_platform
    oauth_scopes     = var.oauth_scopes
    workload_metadata_config {
      mode          = var.metadata_mode
    }
    preemptible = var.preemptible
  }

  upgrade_settings {
    max_surge       = var.max_surge
    max_unavailable = var.max_unavailable
  }

}
