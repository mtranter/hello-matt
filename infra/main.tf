provider "aws" {
  region = "ap-southeast-2"
  default_tags {
    tags = {
      Application = "hello-matt"
    }
  }
}

data "archive_file" "source" {
  output_path = "${path.module}/handler.zip"
  source_dir  = "${path.module}/../dist"
  type        = "zip"
}

module "api_function" {
  source       = "github.com/mtranter/platform-in-a-box-aws//modules/terraform-aws-piab-lambda"
  name         = "hello-mattAPI"
  service_name = "hello-mattAPI"
  runtime      = "nodejs18.x"
  handler      = "api-handler.handler"
  filename     = data.archive_file.source.output_path
  timeout      = 300
  create_dlq = false
  tags       = {}
}

resource "aws_apigatewayv2_api" "api" {
  name          = "hello-matt"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
  integration_method     = "POST"
  integration_uri        = module.api_function.function.invoke_arn
}


resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"

  target             = "integrations/${aws_apigatewayv2_integration.integration.id}"
}


module "api_logs" {
  source = "github.com/mtranter/platform-in-a-box-aws//modules/terraform-aws-piab-log-group"
  name   = "hello-mattApi"
}

resource "aws_apigatewayv2_stage" "live" {
  name   = "live"
  api_id = aws_apigatewayv2_api.api.id
  default_route_settings {
    logging_level            = "INFO"
    detailed_metrics_enabled = true
    throttling_burst_limit   = 1000
    throttling_rate_limit    = 500
  }
  auto_deploy = true
  access_log_settings {
    destination_arn = module.api_logs.log_group.arn
    format = replace(<<EOF
{ "requestId":"$context.requestId",
  "ip": "$context.identity.sourceIp",
  "caller":"$context.identity.caller",
  "user":"$context.identity.user",
  "requestTime":"$context.requestTime",
  "httpMethod":"$context.httpMethod",
  "resourcePath":"$context.resourcePath",
  "path":"$context.path",
  "status":"$context.status",
  "protocol":"$context.protocol",
  "error": "$context.error.message",
  "integrationError": "$context.integrationErrorMessage",
  "integrationLatency": "$context.integration.latency",
  "responseLatency": "$context.responseLatency"
}
EOF
    , "\n", "")
  }
}

resource "aws_lambda_permission" "apigw" {
  action        = "lambda:InvokeFunction"
  function_name = module.api_function.function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

data "aws_region" "here" {}
data "aws_caller_identity" "me" {}

output "service_url" {
  value  = aws_apigatewayv2_stage.live.invoke_url
}