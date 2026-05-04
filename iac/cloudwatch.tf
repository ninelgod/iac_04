resource "aws_cloudwatch_log_group" "upload_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.upload.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "crop_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.crop.function_name}"
  retention_in_days = 14
}

resource "aws_sns_topic" "dlq_alarm_topic" {
  name = "dlq-alarm-${terraform.workspace}"
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "dlq-messages-alarm-${terraform.workspace}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
  alarm_actions = [aws_sns_topic.dlq_alarm_topic.arn]
}