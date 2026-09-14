variable "fqdn" {
  type        = string
  description = "full custom domain such as xyz.example.com"
}

variable "zone_id" {
  type        = string
  description = "route53 hosted zone ID for the domain"
}
