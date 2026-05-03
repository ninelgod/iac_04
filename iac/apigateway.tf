resource "aws_apigatewayv2_api" "apigatewayv2_api" {
  name = "apigatewayv2_api"
  protocol_type = "HTTP"
  cors_configuration {allow_origins = ["*"]}
}

resource "aws_apigatewayv2_integration" "apigatewayv2_integration" {
  api_id = aws_apigatewayv2_api.apigatewayv2_api.id
  integration_type = "AWS_PROXY"
  integration_uri = "arn:placeholder"
}

resource "aws_apigatewayv2_route" "apigatewayv2_route" {
  route_key = "POST /upload"
  api_id = aws_apigatewayv2_api.apigatewayv2_api.id
  target = "integrations/${aws_apigatewayv2_integration.apigatewayv2_integration.id}"
}

resource "aws_apigatewayv2_stage" "apigatewayv2_stage" {
  name = "$default"
  auto_deploy = true
  api_id = aws_apigatewayv2_api.apigatewayv2_api.id
  access_log_settings {destination_arn = aws_cloudwatch_log_group.log_group.arn}
  default_route_settings {throttling_rate_limit = 10000}
}
resource "aws_cloudwatch_log_group" "log_group"{
  name = "/aws/apigateway/image-processor"
  retention_in_days = 14
}
