terraform {
  backend "gcs" {
    bucket = "kentaiso-terraform-bucket"
    prefix = "terraform/gke/app"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.44.2"
    }
  }
}

provider "google" {
  # Configuration options
}
