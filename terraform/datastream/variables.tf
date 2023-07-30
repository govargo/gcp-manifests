variable "gcp_project_name" {
  description = "Google Cloud project name"
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

variable "datastream_cidr" {
  description = "CIDR which Datastream uses in customer project's vpc"
  type        = string
  default     = "10.127.0.0/24"
}
