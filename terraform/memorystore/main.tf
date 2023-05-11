module "memorystore_redis" {
  source  = "terraform-google-modules/memorystore/google"
  version = "7.1.0"

  name          = "${var.env}-redis-instance"
  project       = var.gcp_project_id
  enable_apis   = var.enable_apis
  region        = var.region
  redis_version = "REDIS_6_X"

  reserved_ip_range  = "google-managed-services-${var.gcp_project_name}"
  authorized_network = "projects/${var.gcp_project_id}/global/networks/${var.gcp_project_name}"

  tier         = var.tier
  auth_enabled = var.auth_enabled
  connect_mode = var.connect_mode
  display_name = "${var.env}-redis"
  labels = {
    env = "production"
  }
  memory_size_gb          = 1
  read_replicas_mode      = var.read_replicas_mode
  transit_encryption_mode = var.transit_encryption_mode

  maintenance_policy = {
    ## This is SUNDAY 00:00 in JST, which is converted by UTC
    day = "SATURDAY"
    start_time = {
      hours   = 15
      minutes = 0
      seconds = 0
      nanos   = 0
    }
  }
}

resource "google_secret_manager_secret_version" "redis_password" {
  secret      = "projects/${var.gcp_project_id}/secrets/redis_password"
  secret_data = module.memorystore_redis.auth_string

  depends_on = [module.memorystore_redis.auth_string]
}

resource "google_dns_record_set" "redis_endpoint" {
  project      = var.gcp_project_id
  managed_zone = "${var.gcp_project_name}-org"

  name = "memorystore-redis-0.${var.gcp_project_name}.org."
  type = "A"
  ttl  = 60

  rrdatas = [module.memorystore_redis.host]

  depends_on = [module.memorystore_redis.host]
}
