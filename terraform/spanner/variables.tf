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

variable "region" {
  description = "Region"
  type        = string
  default     = "asia-northeast1"
}

variable "database_dialect" {
  description = "The dialect of the Cloud Spanner Database"
  type        = string
  default     = "GOOGLE_STANDARD_SQL"
}
