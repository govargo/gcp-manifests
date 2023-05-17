## Service APIs

locals {
  services = toset([
    "artifactregistry.googleapis.com",
    "autoscaling.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "cloudapis.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "containerregistry.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "spanner.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com",
    "dataflow.googleapis.com",
    "datapipelines.googleapis.com",
    "notebooks.googleapis.com",
    "aiplatform.googleapis.com"
  ])
}

resource "google_project_service" "service" {
  for_each = local.services
  project  = var.gcp_project_id
  service  = each.value
}

## Storage
resource "google_storage_bucket" "project-storage" {
  name          = var.gcp_project_id
  project       = var.gcp_project_id
  location      = "asia-northeast1"
  force_destroy = true

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

## VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = var.gcp_project_name
  project                 = var.gcp_project_id
  auto_create_subnetworks = var.auto_create_subnetworks
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "subnetwork_app-0" {
  name                     = "${var.env}-app-0"
  project                  = var.gcp_project_id
  ip_cidr_range            = "10.128.0.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = var.private_ip_google_access
  secondary_ip_range = [
    {
      range_name    = "pod"
      ip_cidr_range = "100.64.0.0/14"
    },
    {
      range_name    = "service"
      ip_cidr_range = "100.68.0.0/20"
    }
  ]
}

resource "google_compute_subnetwork" "subnetwork_app-1" {
  name                     = "${var.env}-app-1"
  project                  = var.gcp_project_id
  ip_cidr_range            = "10.129.0.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = var.private_ip_google_access
  secondary_ip_range = [
    {
      range_name    = "pod"
      ip_cidr_range = "101.64.0.0/14"
    },
    {
      range_name    = "service"
      ip_cidr_range = "101.68.0.0/20"
    }
  ]
}

resource "google_compute_subnetwork" "subnetwork_corp-0" {
  name                     = "${var.env}-corp-0"
  project                  = var.gcp_project_id
  ip_cidr_range            = "10.130.0.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = var.private_ip_google_access
  secondary_ip_range = [
    {
      range_name    = "pod"
      ip_cidr_range = "102.64.0.0/14"
    },
    {
      range_name    = "service"
      ip_cidr_range = "102.68.0.0/20"
    }
  ]
}

module "nat_address_asia_northeast1" {
  source       = "terraform-google-modules/address/google"
  version      = "3.1.2"
  project_id   = var.gcp_project_id
  region       = var.region
  address_type = "EXTERNAL"
  names = [
    "${var.env}-app-0-nat-gateway",
    "${var.env}-misc-0-nat-gateway"
  ]
}

module "nat_address_us_central1" {
  source       = "terraform-google-modules/address/google"
  version      = "3.1.2"
  project_id   = var.gcp_project_id
  region       = "us-central1"
  address_type = "EXTERNAL"
  names = [
    "${var.env}-app-1-nat-gateway",
  ]
}

module "cloud_router_app-0" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 5.0.0"
  project = var.gcp_project_id
  name    = "${var.env}-app-0-router"
  network = var.gcp_project_name
  region  = var.region

  nats = [{
    name                               = "${var.env}-app-0-nat-gateway",
    nat_ip_allocate_option             = "MANUAL_ONLY",
    nat_ips                            = ["${var.env}-app-0-nat-gateway"]
    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
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
    module.nat_address_asia_northeast1,
    google_compute_subnetwork.subnetwork_app-0,
  ]
}

module "cloud_router_app-1" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 5.0.0"
  project = var.gcp_project_id
  name    = "${var.env}-app-1-router"
  network = var.gcp_project_name
  region  = "us-central1"

  nats = [{
    name                               = "${var.env}-app-1-nat-gateway",
    nat_ip_allocate_option             = "MANUAL_ONLY",
    nat_ips                            = ["${var.env}-app-1-nat-gateway"]
    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
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
    module.nat_address_us_central1,
    google_compute_subnetwork.subnetwork_app-1,
  ]
}

resource "google_compute_subnetwork" "subnetwork_misc-0" {
  name                     = "${var.env}-misc-0"
  project                  = var.gcp_project_id
  ip_cidr_range            = "10.131.0.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = var.private_ip_google_access
  secondary_ip_range = [
    {
      range_name    = "pod"
      ip_cidr_range = "103.64.0.0/14"
    },
    {
      range_name    = "service"
      ip_cidr_range = "103.68.0.0/20"
    }
  ]
}

module "cloud_router_misc-0" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 5.0.0"
  project = var.gcp_project_id
  name    = "${var.env}-misc-0-router"
  network = var.gcp_project_name
  region  = var.region

  nats = [{
    name                               = "${var.env}-misc-0-nat-gateway",
    nat_ip_allocate_option             = "MANUAL_ONLY",
    nat_ips                            = ["${var.env}-misc-0-nat-gateway"]
    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
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
    module.nat_address_asia_northeast1,
    google_compute_subnetwork.subnetwork_misc-0
  ]
}

module "main-dns-zone" {
  source         = "terraform-google-modules/cloud-dns/google"
  version        = "5.0.0"
  project_id     = var.gcp_project_id
  type           = "public"
  name           = "kentaiso-org"
  domain         = "kentaiso.org."
  enable_logging = false

  dnssec_config = {
    kind          = "dns#managedZoneDnsSecConfig"
    non_existence = "nsec3"
    state         = "on"

    default_key_specs = {
      algorithm  = "rsasha256"
      key_length = 2048
      key_type   = "keySigning"
      kind       = "dns#dnsKeySpec"
    }
    default_key_specs = {
      algorithm  = "rsasha256"
      key_length = 1024
      key_type   = "zoneSigning"
      kind       = "dns#dnsKeySpec"
    }
  }

  depends_on = [
    google_compute_network.vpc_network
  ]
}

## Org Policy
module "disable_policy_requireOsLogin" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.2.2"

  constraint       = "constraints/compute.requireOsLogin"
  policy_type      = "boolean"
  organization_id  = var.organization_id
  enforce          = false
  policy_for       = "project"
  project_id       = var.gcp_project_id
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_vmExternalIpAccess" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.2.2"

  constraint       = "constraints/compute.vmExternalIpAccess"
  policy_type      = "list"
  organization_id  = var.organization_id
  enforce          = false
  policy_for       = "project"
  project_id       = var.gcp_project_id
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_requireShieldedVm" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.2.2"

  constraint       = "constraints/compute.requireShieldedVm"
  policy_type      = "boolean"
  organization_id  = var.organization_id
  enforce          = false
  policy_for       = "project"
  project_id       = var.gcp_project_id
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_restrictVpcPeering" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.2.2"

  constraint       = "constraints/compute.restrictVpcPeering"
  policy_type      = "list"
  organization_id  = var.organization_id
  enforce          = false
  policy_for       = "project"
  project_id       = var.gcp_project_id
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_uniformBucketLevelAccess" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.2.2"

  constraint       = "constraints/storage.uniformBucketLevelAccess"
  policy_type      = "boolean"
  organization_id  = var.organization_id
  enforce          = true
  policy_for       = "project"
  project_id       = var.gcp_project_id
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_publicAccessPrevention" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.2.2"

  constraint       = "constraints/storage.publicAccessPrevention"
  policy_type      = "boolean"
  organization_id  = var.organization_id
  enforce          = true
  policy_for       = "project"
  project_id       = var.gcp_project_id
  exclude_projects = ["${var.organization_id}"]
}

## BigQuery dataset
resource "google_bigquery_dataset" "billing_export" {
  project = var.gcp_project_id

  dataset_id    = "all_billing_data"
  friendly_name = "cloud_billing_billing_export"
  description   = "Cloud Billing data export to BigQuery"
  location      = "asia-northeast1"

  labels = {
    role = "billing"
  }
}

## Service Acount
data "google_compute_default_service_account" "default" {
}

resource "google_project_iam_member" "allow_image_pull" {
  project = var.gcp_project_id
  role   = "roles/artifactregistry.reader"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "allow_logging_writer" {
  project = var.gcp_project_id
  role   = "roles/logging.logWriter"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "allow_pubsub_publisher" {
  project = var.gcp_project_id
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "allow_monitoring_writer" {
  project = var.gcp_project_id
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

## Cloud Build
resource "google_cloudbuild_trigger" "little-server-build-trigger" {
  project  = var.gcp_project_id
  location = "asia-northeast1"
  name     = "little-server-build-trigger"
  filename = "cloudbuild.yaml"

  github {
    owner = "govargo"
    name  = "little-quest-server"
    push {
      branch = "^main$"
    }
  }

  substitutions = {
    "_BUCKET_NAME" = var.gcp_project_id
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
}

## Artifact Registry
resource "google_artifact_registry_repository" "docker_repository" {
  provider = google-beta

  location      = var.region
  repository_id = "little-quest"
  description   = "Docker repository"
  format        = "DOCKER"
}

## Secret
resource "google_secret_manager_secret" "mysql_user_password" {
  project   = var.gcp_project_id
  secret_id = "mysql_user_password"

  labels = {
    role = "mysql_user_password"
  }

  lifecycle {
    prevent_destroy = true
  }

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "mysql_root_password" {
  project   = var.gcp_project_id
  secret_id = "mysql_root_password"

  labels = {
    role = "mysql_root_password"
  }

  lifecycle {
    prevent_destroy = true
  }

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "redis_password" {
  project   = var.gcp_project_id
  secret_id = "redis_password"

  labels = {
    role = "redis_password"
  }

  lifecycle {
    prevent_destroy = true
  }

  replication {
    automatic = true
  }
}
