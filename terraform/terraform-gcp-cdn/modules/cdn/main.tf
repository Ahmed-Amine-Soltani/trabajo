############################# Network configuration #############################
# The default network tier to be configured for the project
resource "google_compute_project_default_network_tier" "default" {
  network_tier = var.google_compute_project_default_network_tier
}

# Reserve an external IP
resource "google_compute_global_address" "default" {
  name         = "static-website-lb-ip"
  address_type = var.google_compute_global_address_type
}

# Get the managed DNS zone
data "google_dns_managed_zone" "default" {
  name = var.google_dns_managed_zone_name
}

# Add the IP to the DNS
resource "google_dns_record_set" "a" {
  name         = format("%s.%s", var.dns_name, data.google_dns_managed_zone.default.dns_name)
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.default.address]
}

# www to non-www redirect
resource "google_dns_record_set" "cname" {
  name         = format("%s.%s.%s", "www", var.dns_name, data.google_dns_managed_zone.default.dns_name)
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "CNAME"
  ttl          = 300
  rrdatas      = [format("%s.%s", var.dns_name, data.google_dns_managed_zone.default.dns_name)]
}


############################# Bucket configuration #############################
# Bucket to store website
resource "google_storage_bucket" "bucket" {
  name                        = var.google_storage_bucket_name
  location                    = var.google_storage_bucket[0].location
  storage_class               = var.google_storage_bucket[0].storage_class
  force_destroy               = var.google_storage_bucket[0].force_destroy
  uniform_bucket_level_access = var.google_storage_bucket[0].uniform_bucket_level_access
  website {
    main_page_suffix = var.google_storage_bucket[0].main_page_suffix
    not_found_page   = var.google_storage_bucket[0].not_found_page
  }
}

# Make new objects public
resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Upload files to the bucket
resource "null_resource" "upload_folder_content" {
  triggers = {
    file_hashes = jsonencode({
      for fn in fileset(var.folder_path, "**") :
      fn => filesha256("${var.folder_path}/${fn}")
    })
  }

  provisioner "local-exec" {
    command = "gsutil cp -r ${var.folder_path}/* gs://${google_storage_bucket.bucket.name}/"
  }

}

############################# LoadBalancer and CDN creation #############################
# GCP forwarding rule
resource "google_compute_global_forwarding_rule" "static-website" {
  name                  = "static-website-forwarding-rule"
  target                = google_compute_target_https_proxy.static-website.id
  port_range            = "443"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.default.address
}


# GCP target proxy
resource "google_compute_target_https_proxy" "static-website" {
  name             = "static-website-cert"
  url_map          = google_compute_url_map.static-website.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}


# GCP URL MAP
resource "google_compute_url_map" "static-website" {
  name            = "url-map-https-target-proxy"
  default_service = google_compute_backend_bucket.default.id
}

# Add the bucket as a CDN backend
resource "google_compute_backend_bucket" "default" {
  name        = "static-website-backend-bucket"
  bucket_name = google_storage_bucket.bucket.name
  enable_cdn  = true
}

# Create HTTPS certificate
resource "google_compute_managed_ssl_certificate" "default" {
  name = "static-website-cert"

  managed {
    domains = [
      google_dns_record_set.a.name,
      google_dns_record_set.cname.name
    ]
  }
}


############################# HTTP-to-HTTPS redirect for HTTP(S) Load Balancing ############################
# GCP forwarding rule http to https
resource "google_compute_global_forwarding_rule" "static-website-forwording" {
  name                  = "static-website-http-to-https-forwarding-rule"
  port_range            = "80"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  target                = google_compute_target_http_proxy.static-website-forwording.id
  ip_address            = google_compute_global_address.default.address
}

# GCP target prox http to https
resource "google_compute_target_http_proxy" "static-website-forwording" {
  name    = "static-website-http-proxy"
  url_map = google_compute_url_map.static-website-forwording.id
}

# GCP target prox http to https
resource "google_compute_url_map" "static-website-forwording" {
  name = "url-map-http-target-proxy"
  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}