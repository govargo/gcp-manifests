## VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = var.gcp_project_name
  project                 = var.gcp_project_id
  auto_create_subnetworks = var.auto_create_subnetworks
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "subnetwork" {
  name                     = var.region
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

## Org Policy
module "disable_policy_requireOsLogin" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1.0"

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
  version = "~> 5.1.0"

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
  version = "~> 5.1.0"

  constraint       = "constraints/compute.requireShieldedVm"
  policy_type      = "boolean"
  organization_id  = var.organization_id
  enforce          = false
  policy_for       = "project"
  project_id       = var.gcp_project_id
  exclude_projects = ["${var.organization_id}"]
}
