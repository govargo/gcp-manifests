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

variable "zone" {
  description = "Zone"
  type        = string
  default     = "asia-northeast1-a"
}

variable "auth_enabled" {
  description = "Indicates whether OSS Redis AUTH is enabled for the instance. If set to true AUTH is enabled on the instance"
  type        = bool
  default     = true
}

variable "connect_mode" {
  description = "The connection mode of the Redis instance. Can be either DIRECT_PEERING or PRIVATE_SERVICE_ACCESS"
  type        = string
  default     = "PRIVATE_SERVICE_ACCESS"
}

variable "enable_apis" {
  description = "Flag for enabling redis.googleapis.com in your project"
  type        = bool
  default     = false
}

variable "read_replicas_mode" {
  description = "Read replicas mode"
  type        = string
  default     = "READ_REPLICAS_DISABLED"
}

variable "tier" {
  description = "The service tier of the instance"
  type        = string
  default     = "STANDARD_HA"
}

variable "transit_encryption_mode" {
  description = "The TLS mode of the Redis instance"
  type        = string
  default     = "DISABLED"
}
