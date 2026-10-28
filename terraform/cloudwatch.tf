
# # ==========================================
# # 1. CLOUDWATCH LOG GROUP
# # ==========================================

# resource "aws_cloudwatch_log_group" "kubemonitor" {
#   count = local.enable_cloudwatch ? 1 : 0

#   name = "/kubemonitor/application"
#   retention_in_days = 7

#   tags = {
#     Name = "kubemonitor-logs"
#   }
# }

# # ==========================================
# # 2. EKS WORKER NODE COUNT ALARM
# # ==========================================

# resource "aws_cloudwatch_metric_alarm" "node_count" {
#   count = local.enable_cloudwatch && local.enable_eks ? 1 : 0

#   alarm_name = "kubemonitor-low-node-count"
#   alarm_description = "Alert when the EKS cluster has fewer than 2 worker nodes"

#   # Where alert comes from
#   namespace = "ContainerInsights"

#   # Count nodes
#   metric_name = "cluster_node_count"

#   # Check average < 2 every 5 minutes for 10 minutes
#   statistic = "Average"
#   period = 300
#   evaluation_periods = 2
#   comparison_operator = "LessThanThreshold"
#   threshold = 2

#   dimensions = {
#     ClusterName = aws_eks_cluster.main[0].name
#   }

#   treat_missing_data = "missing"

#   # Send notification only when SNS is enabled
#   alarm_actions = local.enable_sns ? [
#     aws_sns_topic.alerts[0].arn
#   ] : []

#   tags = {
#     Name = "kubemonitor-node-count-alarm"
#   }
# }
