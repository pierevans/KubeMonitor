resource "aws_iam_role" "cloudwatch_agent_role" {
  name = "kube-monitor-cloudwatch-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role = aws_iam_role.cloudwatch_agent_role.name

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name        = "kube-monitor-high-node-cpu"
  alarm_description = "EKS worker node CPU utilization exceeds 80%"

  namespace   = "ContainerInsights"
  metric_name = "node_cpu_utilization"

  dimensions = {
    ClusterName = aws_eks_cluster.kube-monitor-eks.name
  }

  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 5
  threshold           = 70
  comparison_operator = "GreaterThanThreshold"

  treat_missing_data = "missing"

  alarm_actions = [
    aws_sns_topic.kube-monitor-alerts.arn
  ]

  tags = {
    Name = "kube-monitor-high-node-cpu"
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_pods" {
  alarm_name        = "kube-monitor-unhealthy-pods"
  alarm_description = "One or more EKS Pods have failed"

  namespace   = "ContainerInsights"
  metric_name = "pod_status_failed"

  dimensions = {
    ClusterName = aws_eks_cluster.kube-monitor-eks.name
    Namespace   = "default"
  }

  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  treat_missing_data = "missing"

  tags = {
    Name = "kube-monitor-unhealthy-pods"
  }

  alarm_actions = [
    aws_sns_topic.kube-monitor-alerts.arn
  ]
}

