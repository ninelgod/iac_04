data "archive_file" "upload_zip" {
  type        = "zip"
  source_dir  = "../src/upload-lambda"
  output_path = "../bin/lambda/upload-function.zip"
}

data "archive_file" "crop_zip" {
  type        = "zip"
  source_dir  = "../src/crop-lambda"
  output_path = "../bin/lambda/crop-function.zip"
}

resource "aws_lambda_function" "upload" {
  filename      = data.archive_file.upload_zip.output_path
  function_name = "upload-lambda-${terraform.workspace}"
  role          = aws_iam_role.upload_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  memory_size   = 256
  timeout       = 30

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.images.id
      UPLOAD_PREFIX = "uploads/"
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.upload_lambda.id]
  }
}

resource "aws_lambda_function" "crop" {
  filename      = data.archive_file.crop_zip.output_path
  function_name = "crop-lambda-${terraform.workspace}"
  role          = aws_iam_role.crop_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  memory_size   = 512
  timeout       = 60

  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.images.id
      PROCESSED_PREFIX = "processed/"
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.crop_lambda.id]
  }
}

resource "aws_lambda_event_source_mapping" "crop_sqs" {
  event_source_arn        = aws_sqs_queue.main.arn
  function_name           = aws_lambda_function.crop.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]
}