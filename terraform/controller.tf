#This file automatically handles some dependencies between services.
locals {
  enable_network    = var.services.network || var.services.eks
  enable_eks        = var.services.eks
  enable_ecr        = var.services.ecr
  enable_cloudwatch = var.services.cloudwatch
  enable_cloudtrail = var.services.cloudtrail
  enable_s3_reports = var.services.s3
  enable_sns        = var.services.sns
}