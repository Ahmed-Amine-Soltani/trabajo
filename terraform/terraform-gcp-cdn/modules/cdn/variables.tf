variable "dns_name" {
  type        = string
  description = "this dns_name will be concatenated with the domain name of your public zone to create the FQDN of your load balancer."
  default     = ""
}

variable "google_dns_managed_zone_name" {
  type        = string
  description = "your google managed zone name."
  default     = ""
}

variable "google_storage_bucket_name" {
  type        = string
  description = "the bucket name which must be in the form of domain name and you must establish that you are authorized to use the domain name."
  default     = ""
}

variable "google_compute_project_default_network_tier" {
  type        = string
  description = "The default network tier to be configured for the project. This field can take the following values: PREMIUM or STANDARD."
  default     = "PREMIUM"
}

variable "google_compute_global_address_type" {
  type        = string
  description = "The type of the address to reserve."
  default     = "EXTERNAL"
}

variable "google_storage_bucket" {
  type = list(object({
    location                    = string
    storage_class               = string
    force_destroy               = bool
    uniform_bucket_level_access = bool
    main_page_suffix            = string
    not_found_page              = string
  }))
  description = "the bucket configuration"
  default = [
    {
      location                    = "australia-southeast1"
      storage_class               = "STANDARD"
      force_destroy               = true
      uniform_bucket_level_access = false
      main_page_suffix            = "index.html"
      not_found_page              = "404.html"
    }
  ]
}

variable "folder_path" {
  type        = string
  description = "Path to your folder"
  default     = ""
}