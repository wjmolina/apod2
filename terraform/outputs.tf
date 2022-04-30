output "base_endpoint" {
  value = aws_apigatewayv2_stage.apod2.invoke_url
}
