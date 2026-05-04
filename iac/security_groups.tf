data "aws_prefix_list" "s3" {
  name = "com.amazonaws.us-east-1.s3"
}

resource "aws_security_group" "upload_lambda" {
  name        = "sg-upload-lambda-${terraform.workspace}"
  description = "Upload Lambda"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = data.aws_prefix_list.s3.cidr_blocks
  }

  egress {
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.vpce_sqs.id
  }
}

resource "aws_security_group" "crop_lambda" {
  name        = "sg-crop-lambda-${terraform.workspace}"
  description = "Crop Lambda"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = data.aws_prefix_list.s3.cidr_blocks
  }

  egress {
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.vpce_sqs.id
  }
}

resource "aws_security_group" "vpce_sqs" {
  name        = "sg-vpce-sqs-${terraform.workspace}"
  description = "SQS VPC Endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [
      aws_security_group.upload_lambda.id,
      aws_security_group.crop_lambda.id
    ]
  }
}