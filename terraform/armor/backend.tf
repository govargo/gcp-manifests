terraform {
  backend "gcs" {
    bucket = "kentaiso-terraform-bucket"
    prefix = "terraform/armor"
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
