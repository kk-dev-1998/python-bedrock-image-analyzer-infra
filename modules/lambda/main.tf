########################################
# modules/lambda
#
# Assumes API Gateway (HTTP API) as the entry point; integration is handled in modules/apigateway.
########################################

resource "aws_lambda_function" "api" {
  # checkov:skip=CKV_AWS_50:It is required in Production environment.
  # checkov:skip=CKV_AWS_117:No rescource access in VPC.
  # checkov:skip=CKV_AWS_173:No credentials in envrionment variables.
  # checkov:skip=CKV_AWS_272:No need for personal development and portfolio purpose.
  # checkov:skip=CKV_AWS_116:Currently no asynchronous processing.
  function_name = "${var.project_name}-${var.environment}"
  role          = var.lambda_role_arn
  package_type  = "Image"
  image_uri     = var.image_uri
  timeout       = var.timeout
  memory_size   = var.memory_size

  environment {
    variables = var.environment_variables
  }

  reserved_concurrent_executions = var.reserved_concurrent_executions
}

resource "aws_cloudwatch_log_group" "lambda" {
  # checkov:skip=CKV_AWS_158:It is already encrypted by AWS managed Key. Logs should not contain confidential details.
  # checkov:skip=CKV_AWS_338:It is required in Production enviroment.
  name              = "/aws/lambda/${aws_lambda_function.api.function_name}"
  retention_in_days = var.log_retention_days
}