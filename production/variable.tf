variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "domain_name" {
  description = "The DNS domain name to use"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources are deployed"
  type        = string
}

variable "container_image" {
  description = "ECR or DockerHub image for ECS"
  type        = string
}