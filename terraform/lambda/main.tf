resource "aws_lambda_function" "apod" {
  function_name    = "apod2-${var.function_name}"
  s3_bucket        = var.s3_bucket
  s3_key           = var.s3_key
  runtime          = "python3.9"
  handler          = "${var.function_name}.handler"
  source_code_hash = var.source_code_hash
  role             = var.role
}

resource "aws_apigatewayv2_integration" "apod" {
  api_id             = var.api_id
  integration_uri    = aws_lambda_function.apod.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_lambda_permission" "apod" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.apod.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = var.source_arn
}

resource "aws_apigatewayv2_route" "apod" {
  api_id    = var.api_id
  route_key = "GET /${var.function_name}"
  target    = "integrations/${aws_apigatewayv2_integration.apod.id}"
}
