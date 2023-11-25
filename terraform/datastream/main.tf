data "google_project" "project" {
}

data "google_compute_network" "vpc_network" {
  project = data.google_project.project.project_id
  name    = var.gcp_project_name
}

data "google_compute_default_service_account" "default" {
}

data "google_secret_manager_secret_version" "mysql_datastream_user_password" {
  secret = "mysql_datastream_user_password"
}

resource "google_compute_health_check" "cloudsql_proxy_autohealing" {
  project = data.google_project.project.project_id

  name                = "cloudsql-proxy-health-check"
  check_interval_sec  = 60
  timeout_sec         = 30
  healthy_threshold   = 1
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/liveness"
    port         = "9090"
  }
}

resource "google_compute_firewall" "allow_healthcheck_to_cloudsql_proxy" {
  project = data.google_project.project.project_id

  name        = "allow-healthcheck-to-cloudsql-proxy"
  network     = data.google_compute_network.vpc_network.id
  description = "Allow HTTP Health Check -> Cloud SQL Proxy"

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  target_tags = ["allow-datastream-to-cloudsql"]
}

resource "google_compute_instance_template" "datastream_cloudsql_proxy" {
  project = data.google_project.project.project_id

  name_prefix  = "datastream-cloudsql-proxy-"
  machine_type = "e2-micro"
  region       = var.region
  tags         = ["allow-datastream-to-cloudsql"]

  disk {
    source_image = "debian-cloud/debian-10"
    type         = "PERSISTENT"
    auto_delete  = true
    boot         = true
    disk_type    = "pd-standard"
    disk_size_gb = 10
  }

  scheduling {
    min_node_cpus               = 0
    preemptible                 = true
    automatic_restart           = false
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
    on_host_maintenance         = "TERMINATE"
  }

  network_interface {
    network            = var.gcp_project_name
    subnetwork_project = data.google_project.project.project_id
    subnetwork         = "https://www.googleapis.com/compute/v1/projects/${data.google_project.project.project_id}/regions/${var.region}/subnetworks/${var.env}-app-0"
    stack_type         = "IPV4_ONLY"
  }

  metadata = {
    env  = "${var.env}"
    role = "cloudsql-proxy"
  }

  metadata_startup_script = <<EOF
#! /bin/bash
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

sudo apt -y install wget
wget https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.7.2/cloud-sql-proxy.linux.amd64 -O /usr/local/bin/cloud-sql-proxy
chmod +x /usr/local/bin/cloud-sql-proxy
cloud-sql-proxy --http-address=0.0.0.0 --address 0.0.0.0 --port 3306 --private-ip \
  --structured-logs --max-sigterm-delay=10s --health-check=true \
  ${data.google_project.project.project_id}:${var.region}:prod-mysql-instance
EOF

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["sql-admin", "logging-write", "monitoring-write"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "datastream_cloudsql_proxy_mig" {
  project = data.google_project.project.project_id

  name               = "datastream-cloudsql-proxy-mig"
  base_instance_name = "datastream-cloudsql-proxy"
  zone               = "${var.region}-a"

  target_size = 1

  version {
    instance_template = google_compute_instance_template.datastream_cloudsql_proxy.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.cloudsql_proxy_autohealing.id
    initial_delay_sec = 60
  }

  wait_for_instances        = true
  wait_for_instances_status = "STABLE"

  update_policy {
    type                    = "PROACTIVE"
    replacement_method      = "SUBSTITUTE"
    minimal_action          = "REPLACE"
  }
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [google_compute_instance_group_manager.datastream_cloudsql_proxy_mig]

  create_duration = "60s"
}

data "google_compute_instance_group" "datastream_cloudsql_proxy_mig" {
  name = "datastream-cloudsql-proxy-mig"
  zone = "${var.region}-a"

  depends_on = [google_compute_instance_group_manager.datastream_cloudsql_proxy_mig]
}

data "google_compute_instance" "datastream_cloudsql_proxy_instance" {
  self_link = tolist(data.google_compute_instance_group.datastream_cloudsql_proxy_mig.instances)[0]
  zone      = "${var.region}-a"

  depends_on = [time_sleep.wait_60_seconds]
}

resource "google_dns_record_set" "datastream_cloudsql_proxy" {
  project      = data.google_project.project.project_id
  managed_zone = "${var.gcp_project_name}-demo"

  name = "datastream-cloudsql-proxy.${var.gcp_project_name}.demo.altostrat.com."
  type = "A"
  ttl  = 60

  rrdatas = [data.google_compute_instance.datastream_cloudsql_proxy_instance.network_interface.0.network_ip]

  depends_on = [google_compute_instance_group_manager.datastream_cloudsql_proxy_mig]
}

resource "google_compute_firewall" "allow_datastream_to_cloudsql" {
  project = data.google_project.project.project_id

  name        = "allow-datastream-to-cloudsql"
  network     = data.google_compute_network.vpc_network.id
  description = "Allow Datastream -> Cloud SQL Proxy -> Cloud SQL"

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = [var.datastream_cidr]
  target_tags   = ["allow-datastream-to-cloudsql"]
}

resource "google_datastream_private_connection" "private_mysql_connection" {
  project = data.google_project.project.project_id

  display_name          = "${var.gcp_project_name}-private-mysql-connection"
  location              = var.region
  private_connection_id = "${var.gcp_project_name}-private-mysql-connection"

  labels = {
    env = var.env
  }

  vpc_peering_config {
    vpc    = data.google_compute_network.vpc_network.id
    subnet = var.datastream_cidr
  }
}

resource "google_datastream_connection_profile" "private_mysql_profile" {
  project = data.google_project.project.project_id

  display_name          = "${var.gcp_project_name}-private-mysql-profile"
  location              = var.region
  connection_profile_id = "${var.gcp_project_name}-private-mysql-profile"

  labels = {
    direction = "source"
    kind      = "mysql"
    env       = var.env
  }

  mysql_profile {
    hostname = google_dns_record_set.datastream_cloudsql_proxy.name
    port     = "3306"
    username = "datastream"
    password = data.google_secret_manager_secret_version.mysql_datastream_user_password.secret_data
  }

  private_connectivity {
    private_connection = google_datastream_private_connection.private_mysql_connection.id
  }
}

resource "google_datastream_connection_profile" "destination_bigquery_profile" {
  project = data.google_project.project.project_id

  display_name          = "${var.gcp_project_name}-destination-bigquery-profile"
  location              = var.region
  connection_profile_id = "${var.gcp_project_name}-destination-bigquery-profile"

  labels = {
    direction = "destination"
    kind      = "bigquery"
    env       = var.env
  }

  bigquery_profile {}
}

resource "google_datastream_stream" "masterdata_stream" {
  project = data.google_project.project.project_id

  display_name  = "little-quest-masterdata-stream"
  location      = var.region
  stream_id     = "little-quest-masterdata-stream"
  desired_state = "RUNNING"
  source_config {
    source_connection_profile = google_datastream_connection_profile.private_mysql_profile.id
    mysql_source_config {
      max_concurrent_cdc_tasks = 0
      include_objects {
        mysql_databases {
          database = "master_data"
          mysql_tables {
            table = "master_data_converts"
          }
        }
      }
    }
  }

  destination_config {
    destination_connection_profile = google_datastream_connection_profile.destination_bigquery_profile.id
    bigquery_destination_config {
      data_freshness = "86400s"
      single_target_dataset {
        dataset_id = "${data.google_project.project.project_id}:${var.env}_little_quest_datalake"
      }
    }
  }

  backfill_all {}
  timeouts {}
}
