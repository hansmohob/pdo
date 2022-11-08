# Naming Convention

variable "customer_code" {
  description = "3 or 4 letter unique identifier for a customer"
  type        = string
}

variable "environment_code" {
  description = "2 character code to signify the workloads environment"
  type        = string
}

# Network Variables

variable "vpc_cidr" {
  description = "VPC CIDR range"
  type        = string
}

# Regions

variable "region" {
  description = "AWS region"
  type        = string
}

variable "az_01" {
  description = "Availability Zone 1"
  type        = string
}

variable "az_02" {
  description = "Availability Zone 2"
  type        = string
}

variable "az_03" {
  description = "Availability Zone 3"
  type        = string
}

# Tags

variable "env_name" {

  description = "Environment name tag"
  type        = string
}

variable "customer_name" {

  description = "Customer Name tag"
  type        = string
}