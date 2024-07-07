## Network
resource "google_compute_global_address" "little_quest_server_ip" {
  project       = data.google_project.project.project_id
  name          = "little-quest-server-ip"
  address_type  = "EXTERNAL"
  ip_version    = "IPV4"
  prefix_length = 0
}

resource "google_dns_record_set" "little_quest" {
  project      = data.google_project.project.project_id
  managed_zone = "${var.gcp_project_name}-demo"

  name = "little-quest-server.${var.gcp_project_name}.demo.altostrat.com."
  type = "A"
  ttl  = 60

  rrdatas = [google_compute_global_address.little_quest_server_ip.address]

  depends_on = [google_compute_global_address.little_quest_server_ip]
}

resource "google_compute_managed_ssl_certificate" "little_quest_server_certificate" {
  project = data.google_project.project.project_id
  name    = "little-quest-server-certificate"

  managed {
    domains = ["little-quest-server.${var.gcp_project_name}.demo.altostrat.com."]
  }
}

