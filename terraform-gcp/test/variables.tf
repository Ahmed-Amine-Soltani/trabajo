variable google_project {
  type        = string
  default = "probable-byway-303616"

}

variable region {
  type        = string
  default = "us-central1"

}


variable zone {
  type        = string
  default = "us-central1-c"

}




variable dns_name {
  type        = string
  description = "The dns name to create which point to the CDN"
  default     = "devops-technical.lab.innovorder.io"
}

variable google_dns_managed_zone_name {
  type        = string
  description = "The name of the Google DNS Managed Zone where the DNS will be created"
  default     = "lab-innovorder-io"
}
