output "dns_managed_zone_name" {
  description = "your google managed zone name."
  value       = data.google_dns_managed_zone.default.name
}

output "external_ip_reserved" {
  description = "the ip address which will be mapped to the FQDN in the configuration of your gcp public zone."
  value       = google_compute_global_address.default.address
}

output "lb_fqdn" {
  description = "the FQDN of your load balancer with which you access your website."
  value       = format("%s.%s", var.dns_name, data.google_dns_managed_zone.default.dns_name)
}