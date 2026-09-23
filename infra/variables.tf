variable "region" {
  type        = string
  description = "aws region"
  default     = "eu-west-2"
}
variable "domain_name" {
  type        = string
  default     = "yasirmoosa.tech"
  description = "root domain name yasirmoosa.tech in my case"
}

variable "subdomain" {
  type        = string
  default     = "tm"
  description = "subdomain prefix for the app"

}
