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

resource "google_compute_instance" "datastream_cloudsql_proxy" {
  project = data.google_project.project.project_id

  name         = "datastream-cloudsql-proxy"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  tags = ["allow-datastream-to-cloudsql"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
      labels = {
        env  = var.env
        role = "cloudsql-proxy"
      }
      size = 10
      type = "pd-standard"
    }
  }

  scheduling {
    preemptible        = true
    automatic_restart  = false
    provisioning_model = "SPOT"
  }

  network_interface {
    network            = var.gcp_project_name
    subnetwork_project = data.google_project.project.project_id
    subnetwork         = "${var.env}-app-0"
    stack_type         = "IPV4_ONLY"
  }

  metadata = {
    env  = "${var.env}"
    role = "cloudsql-proxy"
  }

  metadata_startup_script = <<EOF
#! /bin/bash
sudo apt -y install wget
wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O /usr/local/bin/cloud_sql_proxy
chmod +x /usr/local/bin/cloud_sql_proxy
cloud_sql_proxy -instances=${data.google_project.project.project_id}:${var.region}:prod-mysql-instance=tcp:0.0.0.0:3306
EOF

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["sql-admin", "logging-write"]
  }
}

resource "google_dns_record_set" "datastream_cloudsql_proxy" {
  project      = data.google_project.project.project_id
  managed_zone = "${var.gcp_project_name}-org"

  name = "datastream-cloudsql-proxy.${var.gcp_project_name}.org."
  type = "A"
  ttl  = 60

  rrdatas = [google_compute_instance.datastream_cloudsql_proxy.network_interface.0.network_ip]

  depends_on = [google_compute_instance.datastream_cloudsql_proxy]
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
