

# <p align="center"> Setting up a CDN on GCP via Terraform </p> 



<img alt="GitHub tag (latest SemVer)" src="https://img.shields.io/github/v/tag/Ahmed-Amine-Soltani/terraform-gcp-cdn">



### Requirements

------

Before starting you’ll need some pre-existing configurations:

- An existing GCP account linked to a billing account
- An existing GCP project
- A service account with a key
- Terraform installed and configured on your machine
- A domain name managed in Cloud DNS (Public Zone)
- Domain named bucket [verification](https://cloud.google.com/storage/docs/domain-name-verification)
- Some files to upload to the bucket , at least an index page `index.html` and a 404 page `404.html`.
- [gsutil](https://cloud.google.com/storage/docs/gsutil_install) command-line tool.

In order to operate with the Service Account you must activate the following APIs on the project where the Service Account was created:

- Cloud DNS API
- Compute Engine API



### Service account roles to add 

------

- Compute Admin          

- Compute Load Balancer Admin          

- DNS Administrator          

- CA Service Operation Manager          

- Storage Admin          



### Prepare Terraform

------

We need to configure your Terraform to use the GCP and GCP beta  provider first . Don’t forget to  change your variables

```hcl
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
 } 
```



### Bucket configuration

------

We need then to create a GCS bucket to host our static files. 

The bucket name must be a syntactically valid DNS name verified . Examples of valid domain-named buckets include `example.com`, `buckets.example.com`  . 

The `main_page_suffix` is set to `index.html` and `not_found_page` is set to `404.html`

```hcl
# Bucket to store website
resource "google_storage_bucket" "bucket" {
  name                        = var.google_storage_bucket_name
  location                    = "australia-southeast1"
  storage_class               = "STANDARD"
  force_destroy               = true
  uniform_bucket_level_access = false
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

# Make new objects public
resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
```

To  copy folders from local server to Google storage bucket

```hcl
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
```



### Network configuration

------

We also need to create a new IP address, and add it in our DNS, so we’ll be able to get HTTPS certificates later. 

```hcl
# The default network tier to be configured for the project
resource "google_compute_project_default_network_tier" "default" {
  network_tier = "PREMIUM"
}

# Reserve an external IP
resource "google_compute_global_address" "default" {
  name         = "static-website-lb-ip"
  address_type = "EXTERNAL"
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
```



### LoadBalancer and CDN creation

------

We finally create HTTPS LoadBalancer, the CDN, and map them to serve the bucket content .

<img src=.images/load-balancer.png alt="load-balancer" border="0">

```hcl
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
  name             = "static-website-https-proxy"
  url_map          = google_compute_url_map.static-website.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
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

# GCP URL MAP
resource "google_compute_url_map" "static-website" {
  name            = "url-map-https-target-proxy"
  description     = "a description"
  default_service = google_compute_backend_bucket.default.id
}

# Add the bucket as a CDN backend
resource "google_compute_backend_bucket" "default" {
  name        = "static-website-backend-bucket"
  description = "Contains beautiful images"
  bucket_name = google_storage_bucket.bucket.name
  enable_cdn  = true
}
```

HTTP LoadBalancer to redirect the traffic to our HTTPS load balancer.

```hcl
# GCP forwarding rule http to https
resource "google_compute_global_forwarding_rule" "static-website-forwording" {
  name                  = "static-website-http-to-https-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  port_range            = 80
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
```



### Variables 

------

We can declare the variables in the **variables.tf** file or directly in the module block 

```hcl
variable "dns_name" {
  type        = string
  description = "this dns_name will be concatenated with the domain name of your public zone to create the FQDN of your load balancer."
  default     = "lb"
}

variable "google_dns_managed_zone_name" {
  type        = string
  description = "The name of the Google DNS Managed Zone where the DNS will be created"
  default     = "ahmedamine-soltani-lab-innovorder-dev"
}

variable "google_storage_bucket_name" {
  type        = string
  description = "bucket name"
  default     = "test.detect.tn"
}

variable "folder_path" {
  type        = string
  description = "Path to your folder"
  default     = "/path/to/your/folder"
}
```







### Architecture

------

<img src=.images/architecture.png alt="gcp-cdn-architecture" border="0" />

------

The **ressources** that will be created in the chosen project :

- An external IP address  [link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) [link](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address#reserve_new_static) .

- An entry in Cloud DNS to map the IP address to the domain name [link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) [link](https://cloud.google.com/dns/docs/tutorials/create-domain-tutorial#set-up-domain) .
- A GCS bucket [link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) [link](https://cloud.google.com/storage/docs/hosting-static-website) .
- A https external load balancer with CDN  [link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule) [link](https://cloud.google.com/load-balancing/docs/https) .
- A http external load balancer to redirect HTTP traffic to HTTPS [link]()  [link](https://cloud.google.com/cdn/docs/setting-up-http-https-redirect#partial-http-lb) .
- A managed certificate for HTTPS [link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_managed_ssl_certificate) [link](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs) .



### Test the website

------

Check if everything is working as it should be, the FQDN will be mapped directly to the **index.html** page . the FQDN is the concatenation of dns_name that you enter as a variable and the dns name of your public GCP zone .

<img src=.images/test-the-website-prefix.png alt="gcp-cdn-architecture" border="0" />

Here we test the behavior when trying to access a page that does not exist in our bucket .

<img src=.images/not-found-page.png alt="gcp-cdn-architecture" border="0" />