data "archive_file" "apod2" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/package"
  output_path = "${path.module}/../lambda/package.zip"
}

resource "aws_s3_bucket" "apod2" {
  bucket        = "apod2"
  force_destroy = true
}

resource "aws_s3_object" "apod2" {
  bucket = aws_s3_bucket.apod2.id
  key    = "lambda"
  source = data.archive_file.apod2.output_path
}

resource "aws_iam_role" "apod2" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_apigatewayv2_api" "apod2" {
  name          = "apod2"
  protocol_type = "HTTP"
}

module "lambda" {
  for_each = fileset("${path.module}/../lambda", "*.py")

  source = "./lambda"

  function_name = trimsuffix(each.key, ".py")
  s3_bucket     = aws_s3_bucket.apod2.id
  s3_key        = aws_s3_object.apod2.key
  role          = aws_iam_role.apod2.arn
  api_id        = aws_apigatewayv2_api.apod2.id
  execution_arn = aws_apigatewayv2_api.apod2.execution_arn
}

resource "aws_apigatewayv2_stage" "apod2" {
  api_id      = aws_apigatewayv2_api.apod2.id
  name        = "apod2"
  auto_deploy = true
}
