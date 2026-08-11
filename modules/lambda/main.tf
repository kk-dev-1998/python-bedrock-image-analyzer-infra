########################################
# modules/lambda
#
# Assumes API Gateway (HTTP API) as the entry point; integration is handled in modules/apigateway.
########################################

resource "aws_lambda_function" "api" {
  function_name = "${var.project_name}-${var.environment}"
  role          = var.lambda_role_arn
  package_type  = "Image"
  image_uri     = var.image_uri
  timeout       = var.timeout
  memory_size   = var.memory_size

  environment {
    variables = var.environment_variables
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.api.function_name}"
  retention_in_days = var.log_retention_days
}