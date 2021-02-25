# <p align="center"> Terraform CDN Module </p> 



<img alt="GitHub tag (latest SemVer)" src="https://img.shields.io/github/v/tag/Ahmed-Amine-Soltani/terraform-gcp-cdn">





This modules makes it easy to host a static website on Cloud Storage bucket for a domain you own behind a CDN .



The ressources that will be created in your project:

- An external IP address  [link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) [link](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address#reserve_new_static) .

- An entry in Cloud DNS to map the IP address to the domain name [link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) [link](https://cloud.google.com/dns/docs/tutorials/create-domain-tutorial#set-up-domain) .
- A GCS bucket [link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) [link](https://cloud.google.com/storage/docs/hosting-static-website) .
- A https external load balancer with CDN  [link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule) [link](https://cloud.google.com/load-balancing/docs/https) .
- A http external load balancer to redirect HTTP traffic to HTTPS  [link](https://cloud.google.com/cdn/docs/setting-up-http-https-redirect#partial-http-lb) .
- A managed certificate for HTTPS [link](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_managed_ssl_certificate) [link](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs) .





### Usage

------

You can go to the examples folder, however the usage of the module could be like this in your own main.tf file:

```hcl
module "cdn" {
  source  = "Ahmed-Amine-Soltani/cdn/gcp"
  version = "2.0.0"
  dns_name                     = "example"
  google_dns_managed_zone_name = "my-google-dns-managed-zone-name"
  google_storage_bucket_name   = "example.bucket.mydnsname.com"
  folder_path                  = "/path/to/your/folder"
}
```



Then perform the following commands on the root folder:

- `terraform init` to get the plugins.
- `terraform plan` to see the infrastructure plan.
- `terraform apply` to apply the infrastructure build.
- `terraform destroy` to destroy the built infrastructure.





### Inputs

------



| Name                                        | Description                                                  | Type     | Default                | Required |
| :------------------------------------------ | ------------------------------------------------------------ | -------- | ---------------------- | -------- |
| dns_name                                    | this dns_name  will be concatenated with the domain name of your public zone to create the FQDN of your load balancer. | `string` | ""                     | yes      |
| google_dns_managed_zone_name                | your google managed zone name.                               | `string` | ""                     | yes      |
| google_storage_bucket_name                  | the bucket name which must be in the form of domain name and you must establish that you are authorized to use the domain name. the recommended verification method is to verify domain ownership. | `string` | ""                     | yes      |
| folder_path                                 | the path of your folder which contains the files to upload   | `string` | ""                     | yes      |
| google_storage_bucket.location              | where the bucket data will be permanently stored.            | `string` | "australia-southeast1" | no       |
| google_storage_bucket.storage_class         | storage class you set for an object affects the object's availability . STANDARD storage is best for data that is frequently accessed. | `string` | "STANDARD"             | no       |
| google_storage_bucket.force_destroy         | When deleting a bucket, this boolean option will delete all contained objects. | `bool`   | true                   | no       |
| google_storage_bucket.main_page_suffix      | the main page suffix behaves as the bucket's directory index. | `string` | "index.html            | no       |
| google_storage_bucket.not_found_page        | the custom object to return when a requested resource is not found. | `string` | "404.html"             | no       |
| google_compute_project_default_network_tier | Network Service Tiers lets you optimize connectivity between systems on the internet and your Google Cloud instances. Premium Tier delivers traffic on Google's premium backbone. | `string` | "PREMIUM"              | no       |
| google_compute_global_address_type          | Use global external addresses for GFE-based external HTTP(S) load balancers in Premium Tier. | `string` | "EXTERNAL"             | no       |





### Outputs

------

| Name                  | Description                                                  |
| --------------------- | ------------------------------------------------------------ |
| dns_managed_zone_name | your google managed zone name.                               |
| lb_fqdn               | the FQDN of your load balancer with which you access your website. |
| external_ip_reserved  | the ip address which will be mapped to the FQDN in the configuration of your gcp public zone. |



### Requirements

------

Before starting you’ll need some pre-existing configurations:

- An existing GCP account linked to a billing account.
- An existing GCP project.
- A service account with a key.
- Terraform installed and configured on your machine.
- A domain name managed in Cloud DNS (Public Zone).
- Domain named bucket [verification](https://cloud.google.com/storage/docs/domain-name-verification) .
- Some files to upload to the bucket , least an index page `index.html`and a 404 page `404.html`.
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



------

See the module [documentation](https://github.com/Ahmed-Amine-Soltani/terraform-gcp-cdn/blob/master/more-detail.md) for more information.

