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
