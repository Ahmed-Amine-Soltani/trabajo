#terraform {
  #required_version = ">= 0.13.5"

  #required_providers {
    #google = {
      #source  = "hashicorp/google"
      #version = "~> 3.52.0"
    #}

    #google-beta = {
      #source  = "hashicorp/google-beta"
      #version = "~> 3.52.0"
    #}
  #}
#}

provider "google" {
  credentials = file("probable-byway-303616-ab9027296709.json")
  project = var.google_project
  region = var.region 
  zone = var.zone
}

resource "google_compute_network" "vpc_network" {
 name = "terraform-network" 
}

#terraform {
#  backend "gcs" {
#    bucket = "terraformtests"
#    prefix = "terraform1"
#    credentials = "probable-byway-303616-ab9027296709.json"
#   }
#}



#resource "google_compute_instance" "vm_instance" {
  #name         = "terraform-instance"
  #machine_type = "f1-micro"

  #boot_disk {
    #initialize_params {
      #image = "debian-cloud/debian-9"
    #}
  #}

  #network_interface {
    #network = google_compute_network.vpc_network.name
    #access_config {
    #}
  #}
#}
#resource "google_compute_address" "static_ip" {
  #name = "terraform-static-ip"
#}