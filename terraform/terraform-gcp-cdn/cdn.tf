module "cdn" {
  #source = "github.com/Ahmed-Amine-Soltani/terraform-gcp-cdn" # Link to the candidate project
  #source = "./modules/cdn" # Link to the candidate project
  source  = "Ahmed-Amine-Soltani/cdn/gcp"
  version = "2.0.0"

#  dns_name                     = var.dns_name
#  google_dns_managed_zone_name = var.google_dns_managed_zone_name
#  google_storage_bucket_name   = var.google_storage_bucket_name
  dns_name                     = "lb"
  #google_dns_managed_zone_name = "ahmedamine-soltani-lab-innovorder-dev"
  google_dns_managed_zone_name = "my-dns-zone"
  google_storage_bucket_name   = "bucket.detect.tn"
  folder_path = "/home/user-1/Documents/Innovorder/my-tests/website-files-buckup"
}
