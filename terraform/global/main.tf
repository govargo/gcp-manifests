data "google_project" "project" {
}

## Service APIs
locals {
  services = toset([
    "cloudbilling.googleapis.com",
    "artifactregistry.googleapis.com",
    "autoscaling.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "cloudapis.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containersecurity.googleapis.com",
    "containerscanning.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "multiclusterservicediscovery.googleapis.com",
    "gkehub.googleapis.com",
    "trafficdirector.googleapis.com",
    "dns.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudbuild.googleapis.com",
    "containerregistry.googleapis.com",
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "eventarc.googleapis.com",
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
    "aiplatform.googleapis.com",
    "datastudio.googleapis.com",
    "dataform.googleapis.com",
    "datalineage.googleapis.com",
    "datacatalog.googleapis.com",
    "dataplex.googleapis.com",
    "datastream.googleapis.com",
    "workflows.googleapis.com",
    "workflowexecutions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "firebase.googleapis.com",
    "firestore.googleapis.com",
    "securitycenter.googleapis.com",
    "cloudaicompanion.googleapis.com"
  ])
}

resource "google_project_service" "service" {
  for_each = local.services
  project  = data.google_project.project.project_id
  service  = each.value
}

## OAuth Consent
resource "google_iap_brand" "project_brand" {
  project           = data.google_project.project.number
  support_email     = "admin@kentaiso.altostrat.com"
  application_title = "OAuth Consent"
}

## Storage
resource "google_storage_bucket" "project_storage" {
  project       = data.google_project.project.project_id
  name          = data.google_project.project.project_id
  location      = var.region
  force_destroy = true

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

## VPC Network
resource "google_compute_network" "vpc_network" {
  name    = var.gcp_project_name
  project = data.google_project.project.project_id

  auto_create_subnetworks = var.auto_create_subnetworks
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "subnetwork_app_0" {
  name    = "${var.env}-app-0"
  project = data.google_project.project.project_id

  ip_cidr_range            = "10.128.0.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = var.private_ip_google_access
  secondary_ip_range = [
    {
      range_name    = "pod"
      ip_cidr_range = "10.4.0.0/14"
    },
    {
      range_name    = "service"
      ip_cidr_range = "10.8.0.0/20"
    }
  ]
}

resource "google_compute_subnetwork" "subnetwork_app_1" {
  name    = "${var.env}-app-1"
  project = data.google_project.project.project_id

  ip_cidr_range            = "10.129.0.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = var.private_ip_google_access
  secondary_ip_range = [
    {
      range_name    = "pod"
      ip_cidr_range = "10.12.0.0/14"
    },
    {
      range_name    = "service"
      ip_cidr_range = "10.16.0.0/20"
    }
  ]
}

module "nat_address_asia_northeast1" {
  source     = "terraform-google-modules/address/google"
  version    = "3.2.0"
  project_id = data.google_project.project.project_id
  region     = var.region

  address_type = "EXTERNAL"
  names = [
    "${var.env}-app-0-nat-gateway",
    "${var.env}-misc-0-nat-gateway"
  ]
}

module "nat_address_us_central1" {
  source     = "terraform-google-modules/address/google"
  version    = "3.2.0"
  project_id = data.google_project.project.project_id

  region       = "us-central1"
  address_type = "EXTERNAL"
  names = [
    "${var.env}-app-1-nat-gateway",
  ]
}

module "cloud_router_app_0" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.0.2"
  project = data.google_project.project.project_id

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
    google_compute_subnetwork.subnetwork_app_0,
  ]
}

module "cloud_router_app_1" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.0.2"
  project = data.google_project.project.project_id

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
  secondary_ip_range = [
    {
      range_name    = "pod"
      ip_cidr_range = "10.20.0.0/14"
    },
    {
      range_name    = "service"
      ip_cidr_range = "10.24.0.0/20"
    }
  ]
}

resource "google_compute_subnetwork" "subnetwork_misc_0" {
  name    = "${var.env}-misc-0"
  project = data.google_project.project.project_id

  ip_cidr_range            = "10.131.0.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = var.private_ip_google_access
  secondary_ip_range = [
    {
      range_name    = "pod"
      ip_cidr_range = "10.28.0.0/14"
    },
    {
      range_name    = "service"
      ip_cidr_range = "10.32.0.0/20"
    }
  ]
}

module "cloud_router_misc_0" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.0.2"
  project = data.google_project.project.project_id

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
    google_compute_subnetwork.subnetwork_misc_0
  ]
}

module "demo_dns_zone" {
  source     = "terraform-google-modules/cloud-dns/google"
  version    = "5.2.0"
  project_id = data.google_project.project.project_id

  type           = "public"
  name           = "kentaiso-demo"
  domain         = "kentaiso.demo.altostrat.com."
  enable_logging = false

  dnssec_config = {}

  depends_on = [
    google_compute_network.vpc_network
  ]
}

## Org Policy
module "disable_policy_requireOsLogin" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "~> 5.3.0"
  project_id = data.google_project.project.project_id

  constraint       = "constraints/compute.requireOsLogin"
  policy_type      = "boolean"
  organization_id  = var.organization_id
  enforce          = false
  policy_for       = "project"
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_vmExternalIpAccess" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "~> 5.3.0"
  project_id = data.google_project.project.project_id

  constraint       = "constraints/compute.vmExternalIpAccess"
  policy_type      = "list"
  organization_id  = var.organization_id
  enforce          = false
  policy_for       = "project"
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_requireShieldedVm" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "~> 5.3.0"
  project_id = data.google_project.project.project_id

  constraint       = "constraints/compute.requireShieldedVm"
  policy_type      = "boolean"
  organization_id  = var.organization_id
  enforce          = false
  policy_for       = "project"
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_restrictVpcPeering" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "~> 5.3.0"
  project_id = data.google_project.project.project_id

  constraint       = "constraints/compute.restrictVpcPeering"
  policy_type      = "list"
  organization_id  = var.organization_id
  enforce          = false
  policy_for       = "project"
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_uniformBucketLevelAccess" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "~> 5.3.0"
  project_id = data.google_project.project.project_id

  constraint       = "constraints/storage.uniformBucketLevelAccess"
  policy_type      = "boolean"
  organization_id  = var.organization_id
  enforce          = true
  policy_for       = "project"
  exclude_projects = ["${var.organization_id}"]
}

module "disable_policy_publicAccessPrevention" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "~> 5.3.0"
  project_id = data.google_project.project.project_id

  constraint       = "constraints/storage.publicAccessPrevention"
  policy_type      = "boolean"
  organization_id  = var.organization_id
  enforce          = true
  policy_for       = "project"
  exclude_projects = ["${var.organization_id}"]
}

module "allowed-policy-member-domains" {
  source     = "terraform-google-modules/org-policy/google"
  version    = "5.3.0"
  project_id = data.google_project.project.project_id

  constraint      = "constraints/iam.allowedPolicyMemberDomains"
  policy_type     = "list"
  organization_id = var.organization_id
  policy_for      = "project"
  enforce         = false
}

## BigQuery dataset
resource "google_bigquery_dataset" "billing_export" {
  project = data.google_project.project.project_id

  dataset_id            = "all_billing_data"
  friendly_name         = "cloud_billing_billing_export"
  description           = "Cloud Billing data export to BigQuery"
  location              = var.region
  storage_billing_model = "PHYSICAL"

  labels = {
    role = "billing"
  }
}

resource "google_bigquery_dataset" "billing_board" {
  project = data.google_project.project.project_id

  dataset_id    = "billing_board"
  friendly_name = "Cloud Billing Dashboard"
  description   = "BigQuery dataset where the BigQuery views for the billing dashboard"
  location      = var.region

  labels = {
    role = "billing"
  }
}

## Service Acount
data "google_compute_default_service_account" "default" {
}

resource "google_project_iam_member" "allow_image_pull" {
  project = data.google_project.project.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "allow_logging_writer" {
  project = data.google_project.project.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "allow_pubsub_publisher" {
  project = data.google_project.project.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "allow_monitoring_writer" {
  project = data.google_project.project.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "allow_cloudsql_client" {
  project = data.google_project.project.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "allow_securitycommandcenter_agent" {
  project = data.google_project.project.project_id
  role    = "roles/securitycenter.serviceAgent"
  member  = "serviceAccount:service-project-${data.google_project.project.number}@security-center-api.iam.gserviceaccount.com"
}

## Secret
resource "google_secret_manager_secret" "mysql_little_quest_user_password" {
  project   = data.google_project.project.project_id
  secret_id = "mysql_little_quest_user_password"

  labels = {
    role = "mysql_little_quest_user_password"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "mysql_datastream_user_password" {
  project   = data.google_project.project.project_id
  secret_id = "mysql_datastream_user_password"

  labels = {
    role = "mysql_datastream_user_password"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "mysql_root_password" {
  project   = data.google_project.project.project_id
  secret_id = "mysql_root_password"

  labels = {
    role = "mysql_root_password"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "redis_password" {
  project   = data.google_project.project.project_id
  secret_id = "redis_password"

  labels = {
    role = "redis_password"
  }

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_firewall" "allow_all_egress" {
  project     = data.google_project.project.project_id
  name        = "allow-all-egress"
  network     = google_compute_network.vpc_network.id
  description = "Allow all egress"

  direction = "EGRESS"
  priority  = 65535

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "deny_all_ingress" {
  project     = data.google_project.project.project_id
  name        = "deny-all-ingress"
  network     = google_compute_network.vpc_network.id
  description = "Deny all ingress"

  direction = "INGRESS"
  priority  = 65535

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  project     = data.google_project.project.project_id
  name        = "allow-iap-ssh-ingress"
  network     = google_compute_network.vpc_network.id
  description = "Allow SSH via IAP to Compute VMs"

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-datastream-to-cloudsql", "gke-prod-app-0", "gke-prod-corp-0", "gke-prod-misc-0"]
}

## Cloud Pub/Sub
module "gke_cluster_upgrade_notification" {
  source     = "terraform-google-modules/pubsub/google"
  version    = "6.0.0"
  project_id = data.google_project.project.project_id

  topic                            = "gke-cluster-upgrade-notification"
  create_topic                     = true
  grant_token_creator              = true
  topic_message_retention_duration = "604800s"
  topic_labels = {
    env  = "production",
    case = "gke-cluster-upgrade-notification"
  }
}
