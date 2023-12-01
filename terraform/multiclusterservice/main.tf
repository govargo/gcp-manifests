data "google_project" "project" {
}

data "google_container_cluster" "app_0" {
  name     = "${var.env}-app-0"
  location = var.region
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

resource "google_gke_hub_membership" "app_0_agones_allocator_membership" {
  project = data.google_project.project.project_id

  membership_id = "${var.env}-app-0-agones-allocator-membership"
  location      = var.region
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${data.google_container_cluster.app_0.id}"
    }
  }

  depends_on = [google_gke_hub_feature.multi_cluster_service]
}

resource "google_gke_hub_membership" "corp_0_agones_allocator_membership" {
  project = data.google_project.project.project_id

  membership_id = "${var.env}-corp-0-agones-allocator-membership"
  location      = var.region
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${data.google_container_cluster.corp_0.id}"
    }
  }

  depends_on = [google_gke_hub_feature.multi_cluster_service]
}

resource "google_project_iam_member" "allow_network_viewer" {
  project = data.google_project.project.project_id
  role    = "roles/compute.networkViewer"
  member  = "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[gke-mcs/gke-mcs-importer]"

  depends_on = [
    google_gke_hub_feature.multi_cluster_service,
    google_gke_hub_membership.app_0_agones_allocator_membership,
    google_gke_hub_membership.corp_0_agones_allocator_membership
  ]
}

resource "google_project_iam_member" "allow_trafficdirector_client" {
  project = data.google_project.project.project_id
  role    = "roles/trafficdirector.client"
  member  = "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[gke-mcs/gke-mcs-importer]"

  depends_on = [
    google_gke_hub_feature.multi_cluster_service,
    google_gke_hub_membership.app_0_agones_allocator_membership,
    google_gke_hub_membership.corp_0_agones_allocator_membership
  ]
}
