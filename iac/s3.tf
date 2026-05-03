
resource "aws_s3_bucket" "image_processor_env_images_suffix" {
  bucket = "image-processor-env-images-suffix"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.image_processor_env_images_suffix.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.image_processor_env_images_suffix.id
  versioning_configuration {
    status = "Enabled"
  }}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = "${aws_s3_bucket.image_processor_env_images_suffix.id}"
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_configuration" {
  bucket = aws_s3_bucket.image_processor_env_images_suffix.id
  rule {
    id = "rule-1"
    filter {prefix = "uploads/"}
    expiration {days = 30}
    status = "Enabled"
  }
  rule {
    id = "rule-2"
    filter {prefix = "processed/"}
    expiration {days = 90}
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.image_processor_env_images_suffix.id

  queue {
    queue_arn     = aws_sqs_queue.qs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }
  /* Por si pide eventos
  queue {
    queue_arn     = aws_sqs_queue.qs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "processed/"
  }*/
}

resource "aws_sqs_queue" "qs_queue"{
  name = "image-processor-env-image-queue"
  visibility_timeout_seconds = 360
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20  
  redrive_policy = jsonencode({
  deadLetterTargetArn = aws_sqs_queue.image_processor_env_image_dlq.arn
  maxReceiveCount     = 3
})
}

resource "aws_sqs_queue" "image_processor_env_image_dlq" {
  name = "image-processor-env-image-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.qs_queue.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "Cejuwdam"
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action   = "SQS:SendMessage"
      Resource = aws_sqs_queue.qs_queue.arn
      Condition = {
        ArnLike = {
          "aws:SourceArn" = aws_s3_bucket.image_processor_env_images_suffix.arn
        }
      }
    }]
  })
}

