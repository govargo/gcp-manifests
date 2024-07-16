variable "env" {
  description = "environment(e.g. dev, stg, prod)"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
  default     = "asia-northeast1"
}
