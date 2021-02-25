variable "google_project" {
  type    = string
  default = "bustling-cosmos-305616"
}

variable "region" {
  type    = string
  default = "us-central1"
}


variable "zone" {
  type    = string
  default = "us-central1-c"
}

#variable "folder_path" {
  #type        = string
  #description = "Path to your folder"
  #default     = "./test"

#}

variable "key" {
  type    = string
  default = "key.json"

}

#variable "dns_name" {
  #type        = string
  #description = "The dns name to create which point to the CDN"
  #default     = "test"
#}

#variable "google_dns_managed_zone_name" {
  #type        = string
  #description = "The name of the Google DNS Managed Zone where the DNS will be created"
  #default     = "ahmedamine-soltani-lab-innovorder-dev"
#}

#variable "google_storage_bucket_name" {
  #type        = string
  #description = "bucket name"
  #default     = "test.tn"
#}
