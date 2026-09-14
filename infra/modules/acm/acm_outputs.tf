output "certificate_arn" {
  value       = aws_acm_certificate_validation.cert.certificate_arn
  description = "Validated ACM certificate ARN, ready to attach to the ALB listener"
}
