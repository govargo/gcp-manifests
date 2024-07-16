data "google_project" "project" {
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
