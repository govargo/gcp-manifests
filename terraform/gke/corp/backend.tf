terraform {
  backend "gcs" {
    bucket = "kentaiso-terraform-bucket"
    prefix = "terraform/gke/corp"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.39.1"
    }
  }
}

provider "google" {
  # Configuration options
}
