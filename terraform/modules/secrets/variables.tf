variable "environment" {
  type        = string
  description = "environment"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment only accept dev, staging or prod"
  }
}

variable "kms_key_id" {
  type        = string
  description = "KMS key for encryption"
}