terraform {
  required_providers {
    aws = {
      version = "~> 4.12.1"
    }
  }
  backend "s3" {
    bucket = "apod2"
    key    = "terraform-state"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-1"
}

resource "null_resource" "apod2-create" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = <<EOT
      cd ../lambdas
      pip install --target imports $(<requirements.txt)
      cd imports
      zip -r ../imports .
      cd ..
      zip -g imports *
      unzip imports -d package
    EOT
  }
}

data "archive_file" "apod2" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/package"
  output_path = "${path.module}/../lambdas/package.zip"
  depends_on = [
    null_resource.apod2-create
  ]
}

resource "aws_s3_bucket" "apod2" {
  bucket        = "apod2"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "apod2" {
  bucket = aws_s3_bucket.apod2.id
  acl    = "private"
}

resource "aws_s3_object" "apod2" {
  bucket = aws_s3_bucket.apod2.id
  key    = "lambdas"
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

resource "aws_lambda_function" "apod2-get_image" {
  function_name    = "apod2-get_image"
  s3_bucket        = aws_s3_bucket.apod2.id
  s3_key           = aws_s3_object.apod2.key
  runtime          = "python3.9"
  handler          = "get_image.handler"
  source_code_hash = data.archive_file.apod2.output_base64sha256
  role             = aws_iam_role.apod2.arn
}

resource "aws_apigatewayv2_integration" "apod2-get_image" {
  api_id             = aws_apigatewayv2_api.apod2.id
  integration_uri    = aws_lambda_function.apod2-get_image.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_lambda_permission" "apod2-get_image" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.apod2-get_image.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.apod2.execution_arn}/*/*"
}

resource "aws_apigatewayv2_route" "apod2-get_image" {
  api_id    = aws_apigatewayv2_api.apod2.id
  route_key = "GET /get_image"
  target    = "integrations/${aws_apigatewayv2_integration.apod2-get_image.id}"
}

resource "aws_lambda_function" "apod2-create_wallpaper" {
  function_name    = "apod2-create_wallpaper"
  s3_bucket        = aws_s3_bucket.apod2.id
  s3_key           = aws_s3_object.apod2.key
  runtime          = "python3.9"
  handler          = "create_wallpaper.handler"
  source_code_hash = data.archive_file.apod2.output_base64sha256
  role             = aws_iam_role.apod2.arn
}

resource "aws_apigatewayv2_integration" "apod2-create_wallpaper" {
  api_id             = aws_apigatewayv2_api.apod2.id
  integration_uri    = aws_lambda_function.apod2-create_wallpaper.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_lambda_permission" "apod2-create_wallpaper" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.apod2-create_wallpaper.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.apod2.execution_arn}/*/*"
}

resource "aws_apigatewayv2_route" "apod2-create_wallpaper" {
  api_id    = aws_apigatewayv2_api.apod2.id
  route_key = "GET /create_wallpaper"
  target    = "integrations/${aws_apigatewayv2_integration.apod2-create_wallpaper.id}"
}

resource "aws_apigatewayv2_stage" "apod2" {
  api_id      = aws_apigatewayv2_api.apod2.id
  name        = "apod2"
  auto_deploy = true
}

output "base_endpoint" {
  value = aws_apigatewayv2_stage.apod2.invoke_url
}
