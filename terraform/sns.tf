resource "aws_sns_topic" "kube-monitor-alerts" {
  name = "kube-monitor-alerts"
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.kube-monitor-alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}