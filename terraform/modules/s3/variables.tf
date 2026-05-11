variable "bucket_name" {
  type        = string
  description = "bucket name"

  validation {
    condition     = !can(regex("[\\sA-Z]", var.bucket_name))
    error_message = "bucket should lower case and no space"
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

variable "versioning_enabled" {
  type        = bool
  description = "s3 bucket version enablement"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "tags for resources"
}