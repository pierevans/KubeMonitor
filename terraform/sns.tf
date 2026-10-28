
# # ==========================================
# # 1. SNS TOPIC FOR KUBEMONITOR ALERTS
# # ==========================================

# resource "aws_sns_topic" "alerts" {
#   count = local.enable_sns ? 1 : 0

#   name = "kubemonitor-alerts"

#   tags = {
#     Name = "kubemonitor-alerts"
#   }
# }

# # ==========================================
# # 2. SNS EMAIL SUBSCRIPTION
# # ==========================================

# # Assign topic, notification method, recipients
# resource "aws_sns_topic_subscription" "email" {
#   count = local.enable_sns ? 1 : 0

#   topic_arn = aws_sns_topic.alerts[0].arn
#   protocol = "email"
#   endpoint = var.alert_email
# }