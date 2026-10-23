terraform {
  # Minimum terraforn vesion required
  required_version = ">=1.5.0"

  # Minimum aws vesion required
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}