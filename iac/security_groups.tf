data "aws_prefix_list" "s3" {
  name = "com.amazonaws.us-east-1.s3"
}

resource "aws_security_group" "upload_lambda" {
  name        = "upload-lambda-${terraform.workspace}"
  description = "Upload Lambda"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = data.aws_prefix_list.s3.cidr_blocks
  }
}

resource "aws_security_group" "crop_lambda" {
  name        = "crop-lambda-${terraform.workspace}"
  description = "Crop Lambda"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = data.aws_prefix_list.s3.cidr_blocks
  }
}

resource "aws_security_group" "vpce_sqs" {
  name        = "vpce-sqs-${terraform.workspace}"
  description = "SQS VPC Endpoint"
  vpc_id      = aws_vpc.main.id
}

# Reglas que antes causaban ciclos (ahora como recursos separados)
resource "aws_security_group_rule" "upload_to_vpce_sqs" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.upload_lambda.id
  source_security_group_id = aws_security_group.vpce_sqs.id
}

resource "aws_security_group_rule" "crop_to_vpce_sqs" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.crop_lambda.id
  source_security_group_id = aws_security_group.vpce_sqs.id
}

resource "aws_security_group_rule" "vpce_sqs_from_upload" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpce_sqs.id
  source_security_group_id = aws_security_group.upload_lambda.id
}

resource "aws_security_group_rule" "vpce_sqs_from_crop" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpce_sqs.id
  source_security_group_id = aws_security_group.crop_lambda.id
}