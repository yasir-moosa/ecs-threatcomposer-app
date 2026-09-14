variable "fqdn" {
  type        = string
  description = "full domain to create e.g. xyz.example.com"
}

variable "zone_id" {
  type        = string
  description = "route53 hosted zone ID"
}

variable "alb_dns_name" {
  type        = string
  description = "ALB's DNS name to point to"
}

variable "alb_zone_id" {
  type        = string
  description = "ALB's own hosted zone ID - needed for alias records"
}
