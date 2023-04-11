locals {
  read_replica_ip_configuration = {
    ipv4_enabled                                  = var.ipv4_enabled
    require_ssl                                   = var.require_ssl
    private_network                               = "projects/${var.gcp_project_id}/global/networks/${var.gcp_project_name}"
    allocated_ip_range                            = "google-managed-services-${var.gcp_project_name}"
    authorized_networks                           = []
    enable_private_path_for_google_cloud_services = true
  }
}

module "private-service-access" {
  source        = "GoogleCloudPlatform/sql-db/google//modules/private_service_access"
  version       = "14.1.0"
  project_id    = var.gcp_project_id
  vpc_network   = var.gcp_project_name
  ip_version    = "IPV4"
  address       = "10.125.40.0"
  prefix_length = 24
}

module "private-mysql-db" {
  source               = "GoogleCloudPlatform/sql-db/google//modules/mysql"
  version              = "14.1.0"
  name                 = "production"
  random_instance_name = false
  project_id           = var.gcp_project_id

  deletion_protection = false

  database_version                = var.database_version
  region                          = var.region
  zone                            = var.zone
  tier                            = var.tier
  availability_type               = var.availability_type
  maintenance_window_day          = 7
  maintenance_window_hour         = 12
  maintenance_window_update_track = "stable"

  //database_flags = [{ name = "long_query_time", value = 1 }]

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
    private_network                               = "projects/${var.gcp_project_id}/global/networks/${var.gcp_project_name}"
    allocated_ip_range                            = "google-managed-services-${var.gcp_project_name}"
    authorized_networks                           = []
  }

  backup_configuration = {
    enabled                        = true
    binary_log_enabled             = true
    start_time                     = "20:55"
    location                       = null
    transaction_log_retention_days = null
    retained_backups               = 365
    retention_unit                 = "COUNT"
  }

  // Read replica configurations
  read_replica_name_suffix = "-read-replica"
  replica_database_version = var.database_version
  read_replicas = [
    {
      name              = "0"
      zone              = var.zone
      availability_type = "ZONAL"
      tier              = var.tier
      ip_configuration  = local.read_replica_ip_configuration
      insights_config = {
        query_string_length     = 1024
        record_application_tags = true
        record_client_address   = true
      }
      database_flags        = []
      disk_autoresize       = true
      disk_autoresize_limit = 100
      disk_size             = 10
      disk_type             = "PD_HDD"
      user_labels           = { env = "production", role = "read-replica" }
      encryption_key_name   = null
    }
  ]

  db_name      = "master_data"
  db_charset   = "utf8mb4"
  db_collation = "utf8mb4_bin"

  user_name = "application"

  depends_on = [module.private-service-access.peering_completed]
}
