variable "gcp_project_id" {
  description = "GCP project id"
  type        = string
}

variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}

variable "env" {
  description = "environment(e.g. dev, stg, prod)"
  type        = string
}

variable "database_version" {
  description = "The MySQL, PostgreSQL or SQL Server version to use"
  type        = string
  default     = "MYSQL_8_0"
}

variable "region" {
  description = "Region"
  type        = string
  default     = "asia-northeast1"
}

variable "zone" {
  description = "Zone"
  type        = string
  default     = "asia-northeast1-a"
}

variable "tier" {
  description = "The machine type to use"
  type        = string
  default     = "db-f1-micro"
}

variable "availability_type" {
  description = "The availability type of the Cloud SQL instance, high availability (REGIONAL) or single zone (ZONAL)"
  type        = string
  default     = "REGIONAL"
}

variable "ipv4_enabled" {
  description = "Whether this Cloud SQL instance should be assigned a public IPV4 address"
  type        = bool
  default     = false
}

variable "require_ssl" {
  description = "Whether SSL connections over IP are enforced or not"
  type        = bool
  default     = false
}
