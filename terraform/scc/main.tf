data "google_project" "project" {
}

resource "google_scc_mute_config" "open_firewall_agones_gameserver" {
  mute_config_id = "mute-firewall-agones-gameserver"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "resource.name=\"//compute.googleapis.com/projects/${data.google_project.project.project_id}/global/firewalls/3788064070487107887\""
  description    = "Agones gameserver require open ports range, so mute this Open firewall alert"
}
