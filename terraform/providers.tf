#Configure AWS provider for KubeMonitor

provider "aws" {
  # defined in variables.tf
  region  = var.aws_region
  profile = "kubemonitor"

  default_tags {
    tags = {
      Project     = "KubeMonitor"
      Environment = "development"
      ManagedBy   = "Terraform"
    }
  }
}