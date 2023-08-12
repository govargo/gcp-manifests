terraform {
  backend "gcs" {
    bucket = "kentaiso-terraform-bucket"
    prefix = "terraform/functions"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.76.0"
    }
  }
}

provider "google" {
  # Configuration options
}
