
variable "aws_region" {
  description = "AWS region for KubeMonitor"
  type = string
}

variable "alert_email" {
  description = "Email address for receiving KubeMonitor alerts"
  type = string
}
