variable "bucket_info" {
  description = "bucket info"
  type = map(object({
    name       = string
    versioning = bool
    tags       = map(string)
  }))

  validation {
    condition     = alltrue([for v in var.bucket_info : !can(regex("[\\sA-Z]", v.name))])
    error_message = "name should not have white spaces and should lower case"
  }
}

variable "ec2_instance_info" {
  description = "EC2 instance info"
  type = map(object({
    name    = string
    machine = string
    tags    = map(string)
  }))

  validation {
    condition     = alltrue([for v in var.ec2_instance_info : contains(["t3.micro", "t3.small", "t3.medium"], v.machine)])
    error_message = "Acceptable value for machine only t3.micro, t3.small, t3.medium"
  }
}

variable "iam_info" {
  description = "IAM info"
  type = map(object({
    name = string
    tags = map(string)
  }))

  validation {
    condition     = alltrue([for v in var.iam_info : !can(regex("[\\sA-Z]", v.name))])
    error_message = "name should not have white spaces and should lower case"
  }
}