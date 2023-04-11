## Service APIs

locals {
  services = toset([
    "artifactregistry.googleapis.com",
    "autoscaling.googleapis.com",
    "bigquery.googleapis.com",
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
    "sqladmin.googleapis.com"
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
  name                     = "app-0"
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

resource "google_compute_subnetwork" "subnetwork_corp-0" {
  name                     = "corp-0"
  project                  = var.gcp_project_id
  ip_cidr_range            = "10.129.0.0/24"
  region                   = var.region
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

module "nat_address" {
  source       = "terraform-google-modules/address/google"
  version      = "3.1.2"
  project_id   = var.gcp_project_id
  region       = var.region
  address_type = "EXTERNAL"
  names = [
    "app-0-nat-gateway",
    "misc-0-nat-gateway"
  ]
}

module "cloud_router_app-0" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 5.0.0"
  project = var.gcp_project_id
  name    = "app-0-router"
  network = var.gcp_project_name
  region  = var.region

  nats = [{
    name                               = "app-0-nat-gateway",
    nat_ip_allocate_option             = "MANUAL_ONLY",
    nat_ips                            = ["app-0-nat-gateway"]
    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    log_config = {
      enable : true,
      filter : "ERRORS_ONLY"
    }
    subnetworks = [{
      name                    = "app-0",
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }]
  }]

  depends_on = [
    module.nat_address,
  ]
}

resource "google_compute_subnetwork" "subnetwork_misc-0" {
  name                     = "misc-0"
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

module "cloud_router_misc-0" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 5.0.0"
  project = var.gcp_project_id
  name    = "misc-0-router"
  network = var.gcp_project_name
  region  = var.region

  nats = [{
    name                               = "misc-0-nat-gateway",
    nat_ip_allocate_option             = "MANUAL_ONLY",
    nat_ips                            = ["misc-0-nat-gateway"]
    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    log_config = {
      enable : true,
      filter : "ERRORS_ONLY"
    }
    subnetworks = [{
      name                    = "misc-0",
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }]
  }]

  depends_on = [
    module.nat_address,
  ]
}

module "main-dns-zone" {
  source     = "terraform-google-modules/cloud-dns/google"
  version    = "4.2.1"
  project_id = var.gcp_project_id
  type       = "public"
  name       = "kentaiso-org"
  domain     = "kentaiso.org."

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
  }
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

## Service Acount
data "google_compute_default_service_account" "default" {
}

resource "google_project_iam_custom_role" "gmp-rule-evaluator-role" {
  role_id     = "ruleevaluator"
  title       = "GMP Rule Evaluator"
  description = "GMP Rule Evaluator Monitoring role"
  permissions = ["monitoring.timeSeries.create", "monitoring.timeSeries.list"]
  stage       = "GA"
}

resource "google_project_iam_binding" "defaultSA_binding" {
  project = var.gcp_project_id
  role    = "projects/${var.gcp_project_id}/roles/${google_project_iam_custom_role.gmp-rule-evaluator-role.role_id}"

  members = [
    "serviceAccount:${data.google_compute_default_service_account.default.email}",
  ]
  depends_on = [google_project_iam_custom_role.gmp-rule-evaluator-role]
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
    "_BUCKET_NAME" = "kentaiso-330205"
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
}

## Artifact Registry
resource "google_artifact_registry_repository" "docker_repository" {
  provider = google-beta

  location      = "asia-northeast1"
  repository_id = "little-quest"
  description   = "Docker repository"
  format        = "DOCKER"
}
