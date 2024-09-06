terraform {
  backend "gcs" {
    bucket = "kentaiso-terraform-bucket"
    prefix = "terraform/firebase"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.43.1"
    }
  }
}

provider "google" {
  # Configuration options
}
