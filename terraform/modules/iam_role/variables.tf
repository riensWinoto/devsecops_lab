variable "role_name" {
  type        = string
  description = "role name"
}

variable "environment" {
  type        = string
  description = "environment"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment only accept dev, staging or prod"
  }
}

variable "policy_json" {
  type        = string
  description = "json policy"
}
