terraform {
  backend "gcs" {
    bucket = "prd-little-quest-terraform-bucket"
    prefix = "terraform/scc"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.45.0"
    }
  }
}

provider "google" {
  # Configuration options
}
