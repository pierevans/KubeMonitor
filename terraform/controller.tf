
# EKS cluster OIDC identity
data "tls_certificate" "eks" {
  url = aws_eks_cluster.kube-monitor-eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.kube-monitor-eks.identity[0].oidc[0].issuer

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    data.tls_certificate.eks.certificates[0].sha1_fingerprint
  ]
}

# AWS Load Balancer Controller IAM policy
resource "aws_iam_policy" "alb_controller" {
  name   = "KubeMonitorAWSLoadBalancerControllerPolicy"
  policy = file("${path.module}/iam_policy.json")
}

# Trust policy for the controller's Kubernetes ServiceAccount
data "aws_iam_policy_document" "alb_controller_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.eks.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# Controller IAM role
resource "aws_iam_role" "alb_controller" {
  name               = "KubeMonitorAWSLoadBalancerControllerRole"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume.json
}

# Attach controller permissions
resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}


resource "kubernetes_service_account_v1" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.alb_controller
  ]
}

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  wait    = true
  timeout = 600

  set = [
    {
      name  = "clusterName"
      value = aws_eks_cluster.kube-monitor-eks.name
    },
    {
      name  = "region"
      value = var.aws_region
    },
    {
      name  = "vpcId"
      value = aws_vpc.kube-monitor-vpc.id
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    }
  ]

  depends_on = [
    kubernetes_service_account_v1.alb_controller,
    aws_eks_node_group.kube-monitor-workers
  ]
}

resource "aws_iam_role" "api_logs_role" {
  name = "kube-monitor-api-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "api_logs_policy" {
  name = "kube-monitor-api-logs-read"
  role = aws_iam_role.api_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:FilterLogEvents"
      ]
      Resource = aws_cloudwatch_log_group.eks_audit.arn
    }]
  })
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name = aws_eks_cluster.kube-monitor-eks.name
  addon_name   = "metrics-server"

  depends_on = [
    aws_eks_node_group.kube-monitor-workers
  ]

  tags = {
    Name = "kube-monitor-metrics-server"
  }
}

# Create IAM Role for CloudWatch Agent
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.kube-monitor-eks.name
  addon_name   = "eks-pod-identity-agent"

  depends_on = [
    aws_eks_node_group.kube-monitor-workers
  ]
}

resource "aws_eks_pod_identity_association" "api_logs" {
  cluster_name    = aws_eks_cluster.kube-monitor-eks.name
  namespace       = "default"
  service_account = "kube-monitor-api"
  role_arn        = aws_iam_role.api_logs_role.arn

  depends_on = [aws_eks_addon.pod_identity_agent]
}

# Create IAM Role for CloudWatch Agent
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name = aws_eks_cluster.kube-monitor-eks.name
  addon_name   = "amazon-cloudwatch-observability"

  pod_identity_association {
    service_account = "cloudwatch-agent"
    role_arn        = aws_iam_role.cloudwatch_agent_role.arn
  }

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.cloudwatch_agent_policy
  ]

  tags = {
    Name = "kube-monitor-cloudwatch"
  }
}

resource "aws_iam_role_policy" "api_cloudwatch_read" {
  name = "kube-monitor-api-cloudwatch-read"

  role = aws_iam_role.api_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:DescribeAlarms"
        ]

        Resource = "*"
      }
    ]
  })
}