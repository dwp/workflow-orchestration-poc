resource "aws_api_gateway_rest_api" "workflow_orchestrator" {
  name = "workflow_orchestrator"
  description = "API Gateway for interacting with Workflow Orchestrator Service."

  endpoint_configuration {
    types = [
        "PRIVATE"
    ]
    vpc_endpoint_ids = [
        aws_vpc_endpoint.workflow_orchestrator_service.id
    ]
  }
}

resource "aws_api_gateway_rest_api_policy" "workflow_orchestrator" {
  rest_api_id = aws_api_gateway_rest_api.workflow_orchestrator.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "execute-api:Invoke",
      "Resource": "${aws_api_gateway_rest_api.workflow_orchestrator.execution_arn}",
      "Condition": {
        "StringEquals": {
          "aws:SourceVpce": "${aws_vpc_endpoint.workflow_orchestrator_service.id}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_api_gateway_deployment" "workflow_orchestrator" {
  rest_api_id = aws_api_gateway_rest_api.workflow_orchestrator.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.workflow_orchestrator.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [ 
    aws_api_gateway_rest_api_policy.workflow_orchestrator,
    aws_api_gateway_integration.workflow_orchestrator_submit
  ]
}

resource "aws_api_gateway_stage" "workflow_orchestrator" {
  deployment_id = aws_api_gateway_deployment.workflow_orchestrator.id
  rest_api_id   = aws_api_gateway_rest_api.workflow_orchestrator.id
  stage_name    = local.environment
}


# /submit
resource "aws_api_gateway_resource" "workflow_orchestrator_submit" {
  rest_api_id = aws_api_gateway_rest_api.workflow_orchestrator.id
  parent_id = aws_api_gateway_rest_api.workflow_orchestrator.root_resource_id
  path_part = "submit"
}

resource "aws_api_gateway_method" "workflow_orchestrator_submit" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.workflow_orchestrator_submit.id
  rest_api_id   = aws_api_gateway_rest_api.workflow_orchestrator.id
}

resource "aws_api_gateway_integration" "workflow_orchestrator_submit" {
  rest_api_id             = aws_api_gateway_rest_api.workflow_orchestrator.id
  resource_id             = aws_api_gateway_resource.workflow_orchestrator_submit.id
  http_method             = aws_api_gateway_method.workflow_orchestrator_submit.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.workflow_orchestrator_task_submitter_lambda.invoke_arn
}

# /submit/{task_name}
resource "aws_api_gateway_resource" "workflow_orchestrator_task_name" {
  rest_api_id = aws_api_gateway_rest_api.workflow_orchestrator.id
  parent_id = aws_api_gateway_resource.workflow_orchestrator_submit.id
  path_part = "{task_name}"
}

resource "aws_api_gateway_method" "workflow_orchestrator_task_name" {
  http_method   = "POST"
  authorization = "NONE"
  resource_id   = aws_api_gateway_resource.workflow_orchestrator_task_name.id
  rest_api_id   = aws_api_gateway_rest_api.workflow_orchestrator.id

  request_parameters = {
    "method.request.path.task_name" = true
  }
}

resource "aws_api_gateway_integration" "workflow_orchestrator_task_name" {
  rest_api_id             = aws_api_gateway_rest_api.workflow_orchestrator.id
  resource_id             = aws_api_gateway_resource.workflow_orchestrator_task_name.id
  http_method             = aws_api_gateway_method.workflow_orchestrator_task_name.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.workflow_orchestrator_task_submitter_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.id" = "method.request.path.task_name"
  }
}
