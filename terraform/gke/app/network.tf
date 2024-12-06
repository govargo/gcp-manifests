## Network
resource "google_compute_global_address" "little_quest_server_ip" {
  project       = data.google_project.project.project_id
  name          = "little-quest-server-ip"
  address_type  = "EXTERNAL"
  ip_version    = "IPV4"
  prefix_length = 0
}

resource "google_dns_record_set" "little_quest" {
  project      = "kentaiso-330205"
  managed_zone = "kentaiso-demo"

  name = "little-quest-server.kentaiso.demo.altostrat.com."
  type = "A"
  ttl  = 60

  rrdatas = [google_compute_global_address.little_quest_server_ip.address]

  depends_on = [google_compute_global_address.little_quest_server_ip]
}

resource "google_compute_managed_ssl_certificate" "little_quest_server_certificate" {
  project = data.google_project.project.project_id
  name    = "little-quest-server-certificate"

  managed {
    domains = ["little-quest-server.kentaiso.demo.altostrat.com."]
  }

  depends_on = [google_dns_record_set.little_quest]
}

