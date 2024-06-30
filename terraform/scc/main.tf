data "google_project" "project" {
}

resource "google_scc_mute_config" "open_firewall_agones_gameserver" {
  mute_config_id = "mute-firewall-agones-gameserver"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "resource.name=\"//compute.googleapis.com/projects/${data.google_project.project.project_id}/global/firewalls/3788064070487107887\""
  description    = "Agones gameserver require open ports range, so mute this Open firewall alert"
}

resource "google_scc_mute_config" "open_firewall_deny_all_ingress" {
  mute_config_id = "mute-firewall-deny-all-ingress"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "resource.name=\"//compute.googleapis.com/projects/${data.google_project.project.project_id}/global/firewalls/5930557593548618531\""
  description    = "Deny all ingress policy is a deny policy not allow, so mute this Open firewall alert"
}

resource "google_scc_mute_config" "gke_host_namespaces_app_0_node_exporter" {
  mute_config_id = "mute-gke-host-namespace-app-0-node-exporter"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"app-0-prometheus-node-exporter\") AND category=\"GKE_HOST_NAMESPACES\""
  description    = "Node exporter require host namespace, so mute this GKE host namespace alert"
}

resource "google_scc_mute_config" "gke_host_namespaces_corp_0_node_exporter" {
  mute_config_id = "mute-gke-host-namespace-corp-0-node-exporter"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"corp-0-prometheus-node-exporter\") AND category=\"GKE_HOST_NAMESPACES\""
  description    = "Node exporter require host namespace, so mute this GKE host namespace alert"
}

resource "google_scc_mute_config" "gke_host_namespaces_misc_0_node_exporter" {
  mute_config_id = "mute-gke-host-namespace-misc-0-node-exporter"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"misc-0-prometheus-node-exporter\") AND category=\"GKE_HOST_NAMESPACES\""
  description    = "Node exporter require host namespace, so mute this GKE host namespace alert"
}

resource "google_scc_mute_config" "gke_host_ports_app_0_node_exporter" {
  mute_config_id = "mute-gke-host-port-app-0-node-exporter"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"app-0-prometheus-node-exporter\") AND category=\"GKE_HOST_PORTS\""
  description    = "Node exporter require host port, so mute this GKE host port alert"
}

resource "google_scc_mute_config" "gke_host_ports_corp_0_node_exporter" {
  mute_config_id = "mute-gke-host-port-corp-0-node-exporter"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"corp-0-prometheus-node-exporter\") AND category=\"GKE_HOST_PORTS\""
  description    = "Node exporter require host port, so mute this GKE host port alert"
}

resource "google_scc_mute_config" "gke_host_ports_misc_0_node_exporter" {
  mute_config_id = "mute-gke-host-port-misc-0-node-exporter"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"misc-0-prometheus-node-exporter\") AND category=\"GKE_HOST_PORTS\""
  description    = "Node exporter require host port, so mute this GKE host port alert"
}

resource "google_scc_mute_config" "gke_privileged_containers_app_0" {
  mute_config_id = "mute-gke-privileged-containers-app-0"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "(contains(kubernetes.objects, name=\"app-0-falco\") AND contains(kubernetes.objects, name=\"secrets-store-csi-driver\")) AND category=\"GKE_PRIVILEGED_CONTAINERS\""
  description    = "falco and secret csi driver require privileged, so mute this GKE privileged container alert"
}

resource "google_scc_mute_config" "gke_privileged_containers_corp_0" {
  mute_config_id = "mute-gke-privileged-containers-corp-0"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "(contains(kubernetes.objects, name=\"corp-0-falco\") AND contains(kubernetes.objects, name=\"secrets-store-csi-driver\")) AND category=\"GKE_PRIVILEGED_CONTAINERS\""
  description    = "falco and secret csi driver require privileged, so mute this GKE privileged container alert"
}

resource "google_scc_mute_config" "gke_privileged_containers_misc_0" {
  mute_config_id = "mute-gke-privileged-containers-misc-0"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "(contains(kubernetes.objects, name=\"misc-0-falco\") AND contains(kubernetes.objects, name=\"secrets-store-csi-driver\")) AND category=\"GKE_PRIVILEGED_CONTAINERS\""
  description    = "falco and secret csi driver require privileged, so mute this GKE privileged container alert"
}

resource "google_scc_mute_config" "gke_host_path_volumes_app_0_node_exporter" {
  mute_config_id = "mute-gke-host-path-volumes-app-0-node-exporter"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"app-0-prometheus-node-exporter\") AND category=\"GKE_HOST_PATH_VOLUMES\""
  description    = "Node exporter require host path volumes, so mute this GKE host path volumes alert"
}

resource "google_scc_mute_config" "gke_host_path_volumes_corp_0_node_exporter" {
  mute_config_id = "mute-gke-host-path-volumes-corp-0-node-exporter"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"corp-0-prometheus-node-exporter\") AND category=\"GKE_HOST_PATH_VOLUMES\""
  description    = "Node exporter require host path volumes, so mute this GKE host path volumes alert"
}

resource "google_scc_mute_config" "gke_host_path_volumes_misc_0_node_exporter" {
  mute_config_id = "mute-gke-host-path-volumes-misc-0-node-exporter"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"misc-0-prometheus-node-exporter\") AND category=\"GKE_HOST_PATH_VOLUMES\""
  description    = "Node exporter require host path volumes, so mute this GKE host path volumes alert"
}

resource "google_scc_mute_config" "gke_host_path_volumes_app_0_falco" {
  mute_config_id = "mute-gke-host-path-volumes-app-0-falco"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"app-0-falco\") AND category=\"GKE_HOST_PATH_VOLUMES\""
  description    = "Falco require host path volumes, so mute this GKE host path volumes alert"
}

resource "google_scc_mute_config" "gke_host_path_volumes_corp_0_falco" {
  mute_config_id = "mute-gke-host-path-volumes-corp-0-falco"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"corp-0-falco\") AND category=\"GKE_HOST_PATH_VOLUMES\""
  description    = "Falco require host path volumes, so mute this GKE host path volumes alert"
}

resource "google_scc_mute_config" "gke_host_path_volumes_misc_0_falco" {
  mute_config_id = "mute-gke-host-path-volumes-misc-0-falco"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"misc-0-falco\") AND category=\"GKE_HOST_PATH_VOLUMES\""
  description    = "Falco require host path volumes, so mute this GKE host path volumes alert"
}

resource "google_scc_mute_config" "gke_host_path_volumes_secrets_store_csi_driver" {
  mute_config_id = "mute-gke-host-path-volumes-secrets-store-csi-driver"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"secrets-store-csi-driver\") AND category=\"GKE_HOST_PATH_VOLUMES\""
  description    = "Secret Store CSI Driver require host path volumes, so mute this GKE host path volumes alert"
}

resource "google_scc_mute_config" "gke_host_path_volumes_csi_secrets_store_provider_gcp" {
  mute_config_id = "mute-gke-host-path-volumes-csi-secrets-store-provider-gcp"
  parent         = "projects/${data.google_project.project.project_id}"
  filter         = "contains(kubernetes.objects, name=\"csi-secrets-store-provider-gcp\") AND category=\"GKE_HOST_PATH_VOLUMES\""
  description    = "CSI Secret Store Provider Plugin require host path volumes, so mute this GKE host path volumes alert"
}
