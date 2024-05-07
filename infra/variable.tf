variable "aws_region" {
  type        = string
  description = "The AWS region to deploy into."
}

variable "route53_zone_id" {
  type        = string
  description = "The Route53 zone ID to create the DNS records in."
}

variable "application_name" {
  type        = string
  description = "The name of the application."
}

variable "application_description" {
  type        = string
  description = "The description of the application."
}

variable "application_environment" {
  type        = string
  description = "The environment of the application."
}

variable "db_username" {
  type        = string
  description = "The username for the database."
}

variable "db_password" {
  type        = string
  description = "The password for the database."
}

variable "acm_certificate_arn" {
  type        = string
  description = "The ARN of the ACM certificate to use for the load balancer."
}