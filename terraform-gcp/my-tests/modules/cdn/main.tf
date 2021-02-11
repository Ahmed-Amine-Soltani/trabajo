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
  credentials = file(var.key)
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
  force_destroy = true
  uniform_bucket_level_access = false
  website {
    main_page_suffix = "index.html"
    #not_found_page   = "404.html"
  }
}

#resource "google_storage_bucket_object" "object" {
  #name   = "index.html"
 ## bucket = google_storage_bucket.bucket.name
  #bucket = google_storage_bucket.static-site.name
  #source = "website-files/index.html"
  ##source = "git::https://github.com/Ahmed-Amine-Soltani/markdown-language-demo.git"
  ##content = "images"
#}

resource "null_resource" "upload_folder_content" {
 triggers = {
   file_hashes = jsonencode({
   for fn in fileset(var.folder_path, "**") :
   fn => filesha256("${var.folder_path}/${fn}")
   })
 }

 provisioner "local-exec" {
   command = "./google-cloud-sdk/bin/gsutil cp -r ${var.folder_path}/* gs://${google_storage_bucket.static-site.name}/"
 }

}


#resource "google_storage_default_object_access_control" "public_rule" {
  ##bucket = google_storage_bucket.bucket.name
  #bucket = google_storage_bucket.static-site.name
  #role   = "READER"
  #entity = "allUsers"
#}




resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.static-site.name
  role        = "roles/storage.objectViewer"
  member      = "allUsers"
}






resource "google_compute_global_forwarding_rule" "default" {
  name       = "global-rule"
  target     = google_compute_target_https_proxy.default.id
  port_range = "443"
  load_balancing_scheme = "EXTERNAL"
  ip_address = google_compute_global_address.default.address
  #ip_version = "ipv4"
  #network_tier          = "PREMIUM"
}


resource "google_compute_target_https_proxy" "default" {
  name             = "test-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

resource "google_compute_managed_ssl_certificate" "default" {
  name = "test-cert"

  managed {
    domains = [google_dns_record_set.a.name]
  }
}


#resource "google_compute_target_http_proxy" "default" {
  #name        = "target-proxy"
  #description = "a description"
  #url_map     = google_compute_url_map.default.id
#}

resource "google_compute_url_map" "default" {
  name            = "url-map-target-proxy"
  description     = "a description"
  default_service = google_compute_backend_bucket.default.id

#  host_rule {
    #hosts        = [google_dns_record_set.a.name]
    #path_matcher = "allpaths"
  #}

  #path_matcher {
    #name            = "allpaths"
    #default_service = google_compute_backend_bucket.default.id

    #path_rule {
      #paths   = ["/*"]
      #service = google_compute_backend_bucket.default.id
    #}
  #}
}




resource "google_compute_backend_bucket" "default" {
  name        = "image-backend-bucket"
  description = "Contains beautiful images"
  bucket_name = google_storage_bucket.static-site.name
  #enable_cdn  = true
}










resource "google_compute_forwarding_rule" "default" {
  name                  = "website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  port_range            = 80
  ip_address = google_compute_global_address.default.address
}


resource "google_compute_target_http_proxy" "default" {
  name    = "test-proxy"
  url_map = google_compute_url_map.default2.id
}

resource "google_compute_url_map" "default2" {
  name            = "url-map"
  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }  

  host_rule {
    hosts        = [google_dns_record_set.a.name]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    

    path_rule {
      paths   = ["/*"]
     
    }
  }
}






















resource "google_compute_global_address" "default" {
  name = "global-appserver-ip"
}

data "google_dns_managed_zone" "default" {
  name     = "ahmedamine-soltani-lab-innovorder-dev"
}


resource "google_dns_record_set" "a" {
  #name         = "lb.ahmedamine-soltani.lab.innovorder.dev.detect.tn."
  name         = "lb.${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
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