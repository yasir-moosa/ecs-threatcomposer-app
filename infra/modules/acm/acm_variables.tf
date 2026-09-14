variable "fqdn" {
  type        = string
  description = "full domain, e.g. tm.example.com"
}

variable "zone_id" {
  type        = string
  description = "Route53 hosted zone ID for the domain"
}
