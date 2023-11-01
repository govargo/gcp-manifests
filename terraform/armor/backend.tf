terraform {
  backend "gcs" {
    bucket = "kentaiso-terraform-bucket"
    prefix = "terraform/armor"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.60.2"
    }
  }
}

provider "google" {
  # Configuration options
}
