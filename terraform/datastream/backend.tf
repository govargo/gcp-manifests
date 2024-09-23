terraform {
  backend "gcs" {
    bucket = "kentaiso-terraform-bucket"
    prefix = "terraform/datastream"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.44.1"
    }
  }
}

provider "google" {
  # Configuration options
}
