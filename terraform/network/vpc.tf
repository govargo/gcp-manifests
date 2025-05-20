data "google_project" "project" {
}

## VPC Network
resource "google_compute_network" "vpc_network" {
  name    = var.gcp_project_name
  project = data.google_project.project.project_id

  auto_create_subnetworks = var.auto_create_subnetworks
  routing_mode            = var.routing_mode
}

## Sub Network
resource "google_compute_subnetwork" "subnetwork_app_0" {
  name    = "${var.env}-app-0"
  project = data.google_project.project.project_id

  ip_cidr_range            = "10.128.0.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = var.private_ip_google_access
  secondary_ip_range {
    range_name    = "pod"
    ip_cidr_range = "10.4.0.0/14"
  }
  secondary_ip_range {
    range_name    = "service"
    ip_cidr_range = "10.8.0.0/20"
  }
}

resource "google_compute_subnetwork" "subnetwork_app_1" {
  name    = "${var.env}-app-1"
  project = data.google_project.project.project_id

  ip_cidr_range            = "10.129.0.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = var.private_ip_google_access
  secondary_ip_range {
    range_name    = "pod"
    ip_cidr_range = "10.12.0.0/14"
  }
  secondary_ip_range {
    range_name    = "service"
    ip_cidr_range = "10.16.0.0/20"
  }
}

module "cloud_router_app_0" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.3.0"
  project = data.google_project.project.project_id

  name    = "${var.env}-app-0-router"
  network = var.gcp_project_name
  region  = var.region

  nats = [{
    name                                = "${var.env}-app-0-nat-gateway",
    nat_ip_allocate_option              = "AUTO_ONLY",
    source_subnetwork_ip_ranges_to_nat  = "LIST_OF_SUBNETWORKS"
    min_ports_per_vm                    = 64
    max_ports_per_vm                    = 1024
    enable_endpoint_independent_mapping = false
    enable_dynamic_port_allocation      = true
    log_config = {
      enable : true,
      filter : "ERRORS_ONLY"
    }
    subnetworks = [{
      name                    = "${var.env}-app-0",
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }]
  }]

  depends_on = [
    google_compute_subnetwork.subnetwork_app_0,
  ]
}

module "cloud_router_app_1" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.3.0"
  project = data.google_project.project.project_id

  name    = "${var.env}-app-1-router"
  network = var.gcp_project_name
  region  = "us-central1"

  nats = [{
    name                                = "${var.env}-app-1-nat-gateway",
    nat_ip_allocate_option              = "AUTO_ONLY",
    source_subnetwork_ip_ranges_to_nat  = "LIST_OF_SUBNETWORKS"
    min_ports_per_vm                    = 64
    max_ports_per_vm                    = 1024
    enable_endpoint_independent_mapping = false
    enable_dynamic_port_allocation      = true
    log_config = {
      enable : true,
      filter : "ERRORS_ONLY"
    }
    subnetworks = [{
      name                    = "${var.env}-app-1",
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }]
  }]

  depends_on = [
    google_compute_subnetwork.subnetwork_app_1,
  ]
}

resource "google_compute_subnetwork" "subnetwork_corp_0" {
  name    = "${var.env}-corp-0"
  project = data.google_project.project.project_id

  ip_cidr_range            = "10.130.0.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = var.private_ip_google_access
  secondary_ip_range {
    range_name    = "pod"
    ip_cidr_range = "10.20.0.0/14"
  }
  secondary_ip_range {
    range_name    = "service"
    ip_cidr_range = "10.24.0.0/20"
  }
}

resource "google_compute_subnetwork" "subnetwork_misc_0" {
  name    = "${var.env}-misc-0"
  project = data.google_project.project.project_id

  ip_cidr_range            = "10.131.0.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = var.private_ip_google_access
  secondary_ip_range {
    range_name    = "pod"
    ip_cidr_range = "10.28.0.0/14"
  }
  secondary_ip_range {
    range_name    = "service"
    ip_cidr_range = "10.32.0.0/20"
  }
}

module "cloud_router_misc_0" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.3.0"
  project = data.google_project.project.project_id

  name    = "${var.env}-misc-0-router"
  network = var.gcp_project_name
  region  = var.region

  nats = [{
    name                                = "${var.env}-misc-0-nat-gateway",
    nat_ip_allocate_option              = "AUTO_ONLY",
    source_subnetwork_ip_ranges_to_nat  = "LIST_OF_SUBNETWORKS"
    min_ports_per_vm                    = 64
    max_ports_per_vm                    = 1024
    enable_endpoint_independent_mapping = false
    enable_dynamic_port_allocation      = true
    log_config = {
      enable : true,
      filter : "ERRORS_ONLY"
    }
    subnetworks = [{
      name                    = "${var.env}-misc-0",
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }]
  }]

  depends_on = [
    google_compute_subnetwork.subnetwork_misc_0
  ]
}
