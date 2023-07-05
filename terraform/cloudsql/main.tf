data "google_project" "project" {
}

data "google_secret_manager_secret_version" "mysql_root_password" {
  secret = "mysql_root_password"
}

data "google_secret_manager_secret_version" "mysql_little_quest_user_password" {
  secret = "mysql_little_quest_user_password"
}

data "google_secret_manager_secret_version" "mysql_datastream_user_password" {
  secret = "mysql_datastream_user_password"
}

module "private-service-access" {
  source        = "GoogleCloudPlatform/sql-db/google//modules/private_service_access"
  version       = "15.0.0"
  project_id    = data.google_project.project.project_id

  vpc_network   = var.gcp_project_name
  ip_version    = "IPV4"
  address       = "192.168.0.0"
  prefix_length = 16
}

module "cloudsql_mysql" {
  source               = "GoogleCloudPlatform/sql-db/google//modules/mysql"
  version              = "15.0.0"
  name                 = "${var.env}-mysql-instance"
  random_instance_name = false
  project_id           = data.google_project.project.project_id

  deletion_protection = false

  database_version                = var.database_version
  region                          = var.region
  zone                            = var.zone
  tier                            = var.tier
  availability_type               = var.availability_type
  maintenance_window_day          = 7
  maintenance_window_hour         = 12
  maintenance_window_update_track = "stable"

  database_flags = [{ name = "cloudsql_iam_authentication", value = "on" }]

  disk_autoresize       = true
  disk_autoresize_limit = 100
  disk_size             = 10
  disk_type             = "PD_HDD"

  user_labels = {
    env  = "production",
    role = "primary"
  }

  insights_config = {
    query_string_length     = 1024
    record_application_tags = true
    record_client_address   = true
  }

  ip_configuration = {
    ipv4_enabled                                  = var.ipv4_enabled
    enable_private_path_for_google_cloud_services = true
    require_ssl                                   = var.require_ssl
    private_network                               = "${data.google_project.project.id}/global/networks/${var.gcp_project_name}"
    allocated_ip_range                            = "google-managed-services-${var.gcp_project_name}"
    authorized_networks                           = []
  }

  backup_configuration = {
    enabled                        = true
    binary_log_enabled             = true
    point_in_time_recovery_enabled = true
    start_time                     = "23:00"
    location                       = null
    transaction_log_retention_days = 1
    retained_backups               = 1
    retention_unit                 = "COUNT"
  }

  db_name      = "master_data"
  db_charset   = "utf8mb4"
  db_collation = "utf8mb4_bin"

  user_name     = "root"
  user_password = data.google_secret_manager_secret_version.mysql_root_password.secret_data
  root_password = data.google_secret_manager_secret_version.mysql_root_password.secret_data

  depends_on = [module.private-service-access.peering_completed]
}

resource "google_sql_user" "little_quest_user" {
  project = data.google_project.project.project_id

  name     = "little-quest"
  host     = "%"
  instance = module.cloudsql_mysql.instance_name
  type     = "BUILT_IN"
  password = data.google_secret_manager_secret_version.mysql_little_quest_user_password.secret_data

  depends_on = [module.cloudsql_mysql]
}

resource "google_sql_user" "datastream_user" {
  project = data.google_project.project.project_id

  name     = "datastream"
  host     = "%"
  instance = module.cloudsql_mysql.instance_name
  type     = "BUILT_IN"
  password = data.google_secret_manager_secret_version.mysql_datastream_user_password.secret_data

  depends_on = [module.cloudsql_mysql]
}

resource "google_dns_record_set" "mysql_primary_endpoint" {
  project      = data.google_project.project.project_id
  managed_zone = "${var.gcp_project_name}-org"

  name = "cloudsql-mysql-primary.${var.gcp_project_name}.org."
  type = "A"
  ttl  = 60

  rrdatas = [module.cloudsql_mysql.private_ip_address]

  depends_on = [module.cloudsql_mysql.private_ip_address]
}
