variable "username" {
  type        = string
  description = "username"

  validation {
    condition     = !can(regex("[\\sA-Z]", var.username))
    error_message = "username should lower case and no space"
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

variable "tags" {
  type        = map(string)
  description = "tags for resources"
}