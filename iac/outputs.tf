output "api_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "upload_lambda_arn" {
  value = aws_lambda_function.upload.arn
}

output "crop_lambda_arn" {
  value = aws_lambda_function.crop.arn
}