terraform {
  backend "gcs" {
    bucket = "prd-little-quest-terraform-bucket"
    prefix = "terraform/datastream"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.39.0"
    }
  }
}

provider "google" {
  # Configuration options
}
