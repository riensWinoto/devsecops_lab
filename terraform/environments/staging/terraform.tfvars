bucket_info = {
  "raw-data" = {
    name       = "raw-data"
    versioning = false
    tags = {
      data-classification = "confidential"
      owner               = "data-platform"
    }
  }

  "processed-data" = {
    name       = "processed-data"
    versioning = true
    tags = {
      data-classification = "confidential"
      owner               = "data-platform"
    }
  }
}

ec2_instance_info = {
  "data-processor" = {
    name    = "data-processor"
    machine = "t3.micro"
    tags = {
      role  = "data-processor"
      owner = "data-platform"
    }
  }

  "audit-server" = {
    name    = "audit-server"
    machine = "t3.micro"
    tags = {
      role  = "audit-server"
      owner = "data-platform"
    }
  }
}

iam_info = {
  "platform-admin" = {
    name = "platform-admin"
    tags = {
      owner = "data-platform"
    }
  }
}