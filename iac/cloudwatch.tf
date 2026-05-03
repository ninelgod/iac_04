resource "aws_cloudwatch_metric_alarm" "cloudwatch_dlq" {
  alarm_name                = "dlq-messages-alarm"

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1 #En el diagrama no dice cuantos, consideré 1 porque es el mínimo válido
  metric_name               = "ApproximateNumberOfMessagesVisible"
  namespace                 = "AWS/SQS"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 0
  #alarm_description         = ""
  insufficient_data_actions = []
  alarm_actions = 
  dimensions = {QueueName = aws_sqs_queue.image_processor_env_image_dlq.name}
}