
# AWS Provider
provider "aws" {
  region = var.aws_region
}

# Kubernetes Provider
provider "kubernetes" {
  host = aws_eks_cluster.kube-monitor-eks.endpoint

  cluster_ca_certificate = base64decode(
    aws_eks_cluster.kube-monitor-eks.certificate_authority[0].data
  )

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"

    args = [
      "eks",
      "get-token",
      "--region",
      var.aws_region,
      "--cluster-name",
      aws_eks_cluster.kube-monitor-eks.name
    ]
  }
}

# Helm Provider
provider "helm" {
  kubernetes = {
    host = aws_eks_cluster.kube-monitor-eks.endpoint

    cluster_ca_certificate = base64decode(
      aws_eks_cluster.kube-monitor-eks.certificate_authority[0].data
    )

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"

      args = [
        "eks",
        "get-token",
        "--region",
        var.aws_region,
        "--cluster-name",
        aws_eks_cluster.kube-monitor-eks.name
      ]
    }
  }
}
