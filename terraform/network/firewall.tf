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
