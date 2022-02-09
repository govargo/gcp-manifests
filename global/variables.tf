variable "organization_id" {
  description = "Organization id"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project id"
  type        = string
}

variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}

variable "auto_create_subnetworks" {
  description = "Auto subnet create flag"
  type        = bool
  default     = false
}

variable "routing_mode" {
  description = "Network-wide routing mode"
  type        = string
  default     = "REGIONAL"
}

variable "region" {
  description = "Region"
  type        = string
  default     = "asia-northeast1"
}

variable "private_ip_google_access" {
  description = "Internal google access"
  type        = bool
  default     = true
}
