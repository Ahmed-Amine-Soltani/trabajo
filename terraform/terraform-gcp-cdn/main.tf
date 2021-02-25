terraform {
  required_version = ">= 0.13.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.52.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 3.52.0"
    }
  }
}

# GCP provider
provider "google" {
  credentials = file(var.key)
  project     = var.google_project
  region      = var.region
  zone        = var.zone
}

# GCP beta provider
provider "google-beta" {
  credentials = file(var.key)
  project     = var.google_project
  region      = var.region
  zone        = var.zone
}
