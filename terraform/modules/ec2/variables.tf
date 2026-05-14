variable "instance_name" {
  type        = string
  description = "EC2 instance name"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance specs"
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Acceptable value for machine only t3.micro, t3.small, t3.medium"
  }
}

variable "environment" {
  type        = string
  description = "environment"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment only accept dev, staging or prod"
  }
}

variable "ami" {
  type        = string
  description = "OS for EC2"
}

variable "kms_key_id" {
  type        = string
  description = "KMS key for encryption"
}

variable "secret_arn" {
  type        = string
  description = "Secret ARN"
  nullable    = true
}

variable "tags" {
  type        = map(string)
  description = "tags for resources"
}