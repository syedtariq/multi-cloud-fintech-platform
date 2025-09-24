output "cloudwatch_log_group_names" {
  description = "Names of CloudWatch log groups"
  value = [
    aws_cloudwatch_log_group.eks_cluster.name,
    aws_cloudwatch_log_group.application.name,
    aws_cloudwatch_log_group.api_gateway.name
  ]
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.trading_platform.dashboard_name}"
}

output "alarm_names" {
  description = "Names of CloudWatch alarms"
  value = [
    aws_cloudwatch_metric_alarm.high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.high_memory.alarm_name,
    aws_cloudwatch_metric_alarm.api_latency.alarm_name
  ]
}