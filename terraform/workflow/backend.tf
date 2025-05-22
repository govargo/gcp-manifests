terraform {
  backend "gcs" {
    bucket = "prd-little-quest-terraform-bucket"
    prefix = "terraform/workflow"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.36.1"
    }
  }
}

provider "google" {
  # Configuration options
}
