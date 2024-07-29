data "google_project" "project" {
}

data "google_compute_network" "vpc_network" {
  project = data.google_project.project.project_id
  name    = var.gcp_project_name
}

data "google_container_cluster" "app_0" {
  name     = "${var.env}-app-0"
  location = var.region
}

data "google_container_cluster" "app_1" {
  name     = "${var.env}-app-1"
  location = "us-central1"
}

data "google_container_cluster" "corp_0" {
  name     = "${var.env}-corp-0"
  location = var.region
}

## MultiClusterService
resource "google_gke_hub_feature" "multi_cluster_service" {
  project = data.google_project.project.project_id

  name     = "multiclusterservicediscovery"
  location = "global"
  labels = {
    env = "production"
  }
}

## MultiClusterGateway(Ingress)
resource "google_gke_hub_feature" "multi_cluster_gateway" {
  project = data.google_project.project.project_id

  name     = "multiclusteringress"
  location = "global"
  labels = {
    env = "production"
  }

  spec {
    multiclusteringress {
      config_membership = google_gke_hub_membership.app_0_membership.id
    }
  }
}

## Cloud Service Mesh
resource "google_gke_hub_feature" "cloud_service_mesh" {
  project = data.google_project.project.project_id

  name     = "servicemesh"
  location = "global"
  labels = {
    env = "production"
  }
}

## Fleet membership
resource "google_gke_hub_membership" "app_0_membership" {
  project = data.google_project.project.project_id

  membership_id = "${var.env}-app-0-membership"
  location      = var.region
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${data.google_container_cluster.app_0.id}"
    }
  }

  depends_on = [google_gke_hub_feature.multi_cluster_service]
}

resource "google_gke_hub_membership" "app_1_membership" {
  project = data.google_project.project.project_id

  membership_id = "${var.env}-app-1-membership"
  location      = "us-central1"
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${data.google_container_cluster.app_1.id}"
    }
  }

  depends_on = [google_gke_hub_feature.multi_cluster_service]
}

resource "google_gke_hub_membership" "corp_0_membership" {
  project = data.google_project.project.project_id

  membership_id = "${var.env}-corp-0-membership"
  location      = var.region
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${data.google_container_cluster.corp_0.id}"
    }
  }

  depends_on = [google_gke_hub_feature.multi_cluster_service]
}

## Service Mesh Member
resource "google_gke_hub_feature_membership" "app_0_service_mesh_member" {
  project             = data.google_project.project.project_id
  feature             = google_gke_hub_feature.cloud_service_mesh.name
  location            = "global"
  membership          = "projects/${data.google_project.project.number}/locations/${var.region}/memberships/${google_gke_hub_membership.app_0_membership.membership_id}"
  membership_location = var.region
  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }

  depends_on = [google_gke_hub_feature.cloud_service_mesh, google_gke_hub_feature.cloud_service_mesh]
}

resource "google_gke_hub_feature_membership" "app_1_service_mesh_member" {
  project             = data.google_project.project.project_id
  feature             = google_gke_hub_feature.cloud_service_mesh.name
  location            = "global"
  membership          = "projects/${data.google_project.project.number}/locations/us-central1/memberships/${google_gke_hub_membership.app_1_membership.membership_id}"
  membership_location = "us-central1"
  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }

  depends_on = [google_gke_hub_feature.cloud_service_mesh, google_gke_hub_feature.cloud_service_mesh]
}

resource "google_gke_hub_feature_membership" "corp_0_service_mesh_member" {
  project             = data.google_project.project.project_id
  feature             = google_gke_hub_feature.cloud_service_mesh.name
  location            = "global"
  membership          = "projects/${data.google_project.project.number}/locations/${var.region}/memberships/${google_gke_hub_membership.corp_0_membership.membership_id}"
  membership_location = var.region
  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }

  depends_on = [google_gke_hub_feature.cloud_service_mesh, google_gke_hub_feature.cloud_service_mesh]
}

resource "time_sleep" "wait_100_seconds" {
  depends_on = [
    google_gke_hub_feature.multi_cluster_service,
    google_gke_hub_membership.app_0_membership,
    google_gke_hub_membership.app_1_membership,
    google_gke_hub_membership.corp_0_membership
  ]

  create_duration = "100s"
}

resource "google_project_iam_member" "allow_network_viewer" {
  project = data.google_project.project.project_id
  role    = "roles/compute.networkViewer"
  member  = "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[gke-mcs/gke-mcs-importer]"

  depends_on = [time_sleep.wait_100_seconds]
}

resource "google_project_iam_member" "allow_trafficdirector_client" {
  project = data.google_project.project.project_id
  role    = "roles/trafficdirector.client"
  member  = "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[gke-mcs/gke-mcs-importer]"

  depends_on = [time_sleep.wait_100_seconds]
}

resource "google_project_iam_member" "allow_container_admin" {
  project = data.google_project.project.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-multiclusteringress.iam.gserviceaccount.com"

  depends_on = [time_sleep.wait_100_seconds]
}

resource "google_project_iam_member" "allow_service_agent" {
  project = data.google_project.project.project_id
  role    = "roles/anthosservicemesh.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-servicemesh.iam.gserviceaccount.com"

  depends_on = [time_sleep.wait_100_seconds]
}

## Firewall
resource "google_compute_firewall" "allow_istio_multicluster_pods" {
  project     = data.google_project.project.project_id
  name        = "allow-istio-multicluster-pods"
  network     = data.google_compute_network.vpc_network.id
  description = "Allow communication between multi clusters by Cloud Service Mesh Istio Cluster-mesh"

  direction = "INGRESS"
  priority  = 900

  allow {
    protocol = "all"
  }

  source_ranges = [
    data.google_container_cluster.app_0.ip_allocation_policy[0].cluster_ipv4_cidr_block,
    data.google_container_cluster.app_1.ip_allocation_policy[0].cluster_ipv4_cidr_block,
    data.google_container_cluster.corp_0.ip_allocation_policy[0].cluster_ipv4_cidr_block,
  ]

  target_tags = [
    data.google_container_cluster.app_0.node_config[0].tags[0],
    data.google_container_cluster.app_1.node_config[0].tags[0],
    data.google_container_cluster.corp_0.node_config[0].tags[0],
  ]
}

resource "google_compute_firewall" "allow_prod_app_0_kube_api_server_to_webhook" {
  project     = data.google_project.project.project_id
  name        = "allow-prod-app-0-kube-api-server-to-webhook"
  network     = data.google_compute_network.vpc_network.id
  description = "Allow communication between kube-api-server and admission webhook for private cluster prod-app-0"

  direction = "INGRESS"
  priority  = 900

  allow {
    protocol = "tcp"
    ports    = ["15017"]
  }

  source_ranges = [
    data.google_container_cluster.app_0.private_cluster_config[0].master_ipv4_cidr_block,
  ]

  target_tags = [
    data.google_container_cluster.app_0.node_config[0].tags[0],
  ]
}

resource "google_compute_firewall" "allow_prod_app_1_kube_api_server_to_webhook" {
  project     = data.google_project.project.project_id
  name        = "allow-prod-app-1-kube-api-server-to-webhook"
  network     = data.google_compute_network.vpc_network.id
  description = "Allow communication between kube-api-server and admission webhook for private cluster prod-app-1"

  direction = "INGRESS"
  priority  = 900

  allow {
    protocol = "tcp"
    ports    = ["15017"]
  }

  source_ranges = [
    data.google_container_cluster.app_1.private_cluster_config[0].master_ipv4_cidr_block,
  ]

  target_tags = [
    data.google_container_cluster.app_1.node_config[0].tags[0],
  ]
}

resource "google_compute_firewall" "allow_prod_app_0_istioctl_proxy_debug" {
  project     = data.google_project.project.project_id
  name        = "allow-prod-app-0-istioctl-proxy-debug"
  network     = data.google_compute_network.vpc_network.id
  description = "Allow istioctl debug by istioctl version and istioctl ps"

  direction = "INGRESS"
  priority  = 900

  allow {
    protocol = "tcp"
    ports    = ["8080", "15014"]
  }

  source_ranges = [
    data.google_container_cluster.app_0.private_cluster_config[0].master_ipv4_cidr_block,
  ]

  target_tags = [
    data.google_container_cluster.app_0.node_config[0].tags[0],
  ]
}

resource "google_compute_firewall" "allow_prod_app_1_istioctl_proxy_debug" {
  project     = data.google_project.project.project_id
  name        = "allow-prod-app-1-istioctl-proxy-debug"
  network     = data.google_compute_network.vpc_network.id
  description = "Allow istioctl debug by istioctl version and istioctl ps"

  direction = "INGRESS"
  priority  = 900

  allow {
    protocol = "tcp"
    ports    = ["8080", "15014"]
  }

  source_ranges = [
    data.google_container_cluster.app_1.private_cluster_config[0].master_ipv4_cidr_block,
  ]

  target_tags = [
    data.google_container_cluster.app_1.node_config[0].tags[0],
  ]
}
