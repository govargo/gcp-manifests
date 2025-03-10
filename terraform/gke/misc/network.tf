## Network
resource "google_compute_global_address" "argocd_server_ip" {
  project       = data.google_project.project.project_id
  name          = "argocd-server-ip"
  address_type  = "EXTERNAL"
  ip_version    = "IPV4"
  prefix_length = 0
}

resource "google_dns_record_set" "argocd_server" {
  project      = "kentaiso-330205"
  managed_zone = "kentaiso-demo"

  name = "argocd.kentaiso.demo.altostrat.com."
  type = "A"
  ttl  = 60

  rrdatas = [google_compute_global_address.argocd_server_ip.address]

  depends_on = [google_compute_global_address.argocd_server_ip]
}
