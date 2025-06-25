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

data "google_sql_database_instance" "cloudsql_mysql_instance" {
  project = data.google_project.project.project_id
  name    = "${var.env}-mysql-instance"
}

# Need to execute gcloud command with --validate-only flag
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/datastream_private_connection#nested_psc_interface_config
resource "google_compute_network_attachment" "datastream_psc_network_attachment" {
  project = data.google_project.project.project_id

  name                  = "datastream-psc-network-attachment"
  region                = var.region
  description           = "Network Attachment for Datastream Producer VPC"
  connection_preference = "ACCEPT_MANUAL"

  producer_accept_lists = ["d7c3726edb939bf87p-tp"]

  subnetworks = [
    "https://www.googleapis.com/compute/v1/projects/${data.google_project.project.project_id}/regions/${var.region}/subnetworks/${var.env}-app-0"
  ]
}

resource "google_datastream_private_connection" "private_mysql_connection" {
  project = data.google_project.project.project_id

  display_name          = "${var.gcp_project_name}-private-mysql-connection"
  location              = var.region
  private_connection_id = "${var.gcp_project_name}-private-mysql-connection"

  labels = {
    env = var.env
  }

  psc_interface_config {
    network_attachment = google_compute_network_attachment.datastream_psc_network_attachment.id
  }

  depends_on = [google_compute_network_attachment.datastream_psc_network_attachment]
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
    hostname = data.google_sql_database_instance.cloudsql_mysql_instance.ip_address.0.ip_address
    port     = "3306"
    username = "datastream"
    password = data.google_secret_manager_secret_version.mysql_datastream_user_password.secret_data
  }

  private_connectivity {
    private_connection = google_datastream_private_connection.private_mysql_connection.id
  }

  depends_on = [google_datastream_private_connection.private_mysql_connection]
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

  depends_on = [google_datastream_private_connection.private_mysql_connection, google_datastream_connection_profile.private_mysql_profile]
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

  depends_on = [google_datastream_connection_profile.destination_bigquery_profile]
}
