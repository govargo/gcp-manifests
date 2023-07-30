terraform {
  backend "gcs" {
    bucket = "kentaiso-terraform-bucket"
    prefix = "terraform/dataplex"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.74.0"
    }
  }
}

provider "google" {
  # Configuration options
}
