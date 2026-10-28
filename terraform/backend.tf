terraform {
  backend "s3" {
    bucket = "kube-monitor-tfstate-bucket"
    key = "terraform/terraform.tfstate"
    region = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

