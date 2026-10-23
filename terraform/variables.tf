
variable "aws_region" {
  description = "AWS region for KubeMonitor"
  type = string
  default = "us-east-2"
}

variable "alert_email" {
  description = "Email address for receiving KubeMonitor alerts"
  type = string
}

variable "services" {
  description = "Enable or disable AWS services"

  type = object({
    network = bool
    eks = bool
    ecr = bool
    cloudwatch = bool
    cloudtrail = bool
    s3 = bool
    sns = bool
  })
}