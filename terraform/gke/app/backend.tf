terraform {
  backend "gcs" {
    bucket = "kentaiso-terraform-bucket"
    prefix = "terraform/gke/app"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.10.0"
    }
  }
}

provider "google" {
  # Configuration options
}
