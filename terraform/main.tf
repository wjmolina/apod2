resource "aws_s3_object" "apod2-lambda" {
  for_each = fileset("../lambda", "*/*.py")

  bucket = "apod2"
  key    = "lambda-${dirname(each.value)}"
  source = "../lambda/${dirname(each.value)}/package.zip"
  etag   = filebase64sha256("../lambda/${dirname(each.value)}/package.zip")
}

resource "aws_s3_object" "apod2-index" {
  bucket = "apod2"
  key    = "index"
  source = "../index.html"
}

resource "aws_iam_role" "apod2" {
  name                = "terraform-role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

resource "aws_apigatewayv2_api" "apod2" {
  name          = "apod2"
  protocol_type = "HTTP"
}

module "lambda" {
  for_each = fileset("../lambda", "*/*.py")

  source = "./lambda"

  function_name = dirname(each.value)
  s3_bucket     = "apod2"
  s3_key        = "lambda-${dirname(each.value)}"
  role          = aws_iam_role.apod2.arn
  api_id        = aws_apigatewayv2_api.apod2.id
  execution_arn = aws_apigatewayv2_api.apod2.execution_arn

  depends_on = [
    aws_s3_object.apod2-lambda
  ]
}

resource "aws_apigatewayv2_stage" "apod2" {
  api_id      = aws_apigatewayv2_api.apod2.id
  name        = "apod2"
  auto_deploy = true
}
