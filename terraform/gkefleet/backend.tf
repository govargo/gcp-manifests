terraform {
  backend "gcs" {
    bucket = "prd-little-quest-terraform-bucket"
    prefix = "terraform/gkefleet"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
  }
}

provider "google" {
  # Configuration options
}
