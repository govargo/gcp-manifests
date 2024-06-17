terraform {
  backend "gcs" {
    bucket = "kentaiso-terraform-bucket"
    prefix = "terraform/logging"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.33.0"
    }
  }
}

provider "google" {
  # Configuration options
}
