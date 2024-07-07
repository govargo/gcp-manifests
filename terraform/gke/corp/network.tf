resource "google_compute_firewall" "allow_agones_gameserver_ingress" {
  project = data.google_project.project.project_id

  name        = "allow-agones-gameserver-ingress"
  network     = data.google_compute_network.vpc_network.id
  description = "Allow Game Client -> Agones GameServer"

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["7000-8000"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["gke-${var.env}-corp-0-agones-gameserver-pool"]
}