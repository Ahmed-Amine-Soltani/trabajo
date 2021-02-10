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

provider "google" {
  credentials = file("./probable-byway-303616-ab9027296709.json")
  project = var.google_project
  region = var.region 
  zone = var.zone
}



#resource "google_storage_bucket" "bucket" {
resource "google_storage_bucket" "static-site" {
#  name = "bucket-detect-tn"
  name = "bucket.detect.tn"
  location = "australia-southeast1"
  storage_class = "STANDARD"
  #uniform_bucket_level_access = true
  website {
    main_page_suffix = "index.html"
    #not_found_page   = "404.html"
  }
}

resource "google_storage_bucket_object" "object" {
  name   = "public-object"
 # bucket = google_storage_bucket.bucket.name
  bucket = google_storage_bucket.static-site.name
 # source = "website-files/images/banner.jpg"
}

resource "null_resource" "upload_folder_content" {
 triggers = {
   file_hashes = jsonencode({
   for fn in fileset(var.folder_path, "**") :
   fn => filesha256("${var.folder_path}/${fn}")
   })
 }

 provisioner "local-exec" {
   command = "gsutil cp -r ${var.folder_path}/* gs://${google_storage_bucket.static-site.nam}/"
 }

}






resource "google_storage_default_object_access_control" "public_rule" {
  #bucket = google_storage_bucket.bucket.name
  bucket = google_storage_bucket.static-site.name
  role   = "READER"
  entity = "allUsers"
}



resource "google_compute_global_address" "default" {
  name = "global-appserver-ip"
}



resource "google_dns_record_set" "a" {
  name         = "backend.ahmedamine-soltani.lab.innovorder.dev.detect.tn."
  managed_zone = "ahmedamine-soltani-lab-innovorder-dev"
  type         = "A"
  ttl          = 300

  rrdatas = [google_compute_global_address.default.address]

}










































#resource "google_storage_default_object_access_control" "public_rule" {
  ##bucket = google_storage_bucket.bucket.name
  #bucket = google_storage_bucket.static-site.name
  #role   = "READER"
  #entity = "allUsers"
#}




#resource "google_storage_bucket_iam_member" "member" {
  #bucket = google_storage_bucket.static-site.name
  #role = "roles/storage.admin"
  #member = "allUsers"
#}




#resource "google_compute_network" "vpc_network" {
 #name = "terraform-network" 
#}

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