resource "aws_iam_role" "workflow_orchestrator_event_listener" {
  name               = "wo_event_listener"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "workflow_orchestrator_event_listener_lambda_logs" {
  role       = aws_iam_role.workflow_orchestrator_event_listener.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "workflow_orchestrator_event_listener_lambda_xray" {
  role = aws_iam_role.workflow_orchestrator_event_listener.name
  policy_arn = aws_iam_policy.lambda_xray.arn
}

resource "aws_iam_role_policy_attachment" "workflow_orchestrator_event_listener_lambda_vpc_deployment" {
  role = aws_iam_role.workflow_orchestrator_event_listener.name
  policy_arn = aws_iam_policy.lambda_vpc_deployment.arn
}

resource "aws_iam_role_policy_attachment" "workflow_orchestrator_event_listener_lambda_to_sns" {
  role = aws_iam_role.workflow_orchestrator_event_listener.name
  policy_arn = aws_iam_policy.lambda_to_sns.arn
}

data "archive_file" "workflow_orchestrator_event_listener_lambda" {
  type        = "zip"
  source_dir = "${path.module}/wo-event-listener-lambda/"
  excludes = [
    "${path.module}/wo-event-listener-lambda/test*"
  ]
  output_path = "workflow_orchestrator_event_listener_lambda.zip"
}

resource "aws_security_group" "workflow_orchestrator_event_listener" {
  name        = "wo_event_listener"
  description = "Workflow Orchestrator Event Listener Lambda Security Group."
  vpc_id      = data.terraform_remote_state.azkaban.outputs.workflow_manager_vpc.vpc.id
  tags        = merge(local.tags, { Name = local.name })
}

resource "aws_security_group_rule" "workflow_orchestration_event_listener_output" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.workflow_orchestrator_event_listener.id
  cidr_blocks       = ["0.0.0.0/0"] 
}

resource "aws_lambda_function" "workflow_orchestrator_event_listener_lambda" {
    filename = "${path.module}/workflow_orchestrator_event_listener_lambda.zip"
    function_name = "workflow_orchestrator_event_listener"
    role = aws_iam_role.workflow_orchestrator_event_listener.arn
    handler = "handler.handler"
    source_code_hash = data.archive_file.workflow_orchestrator_event_listener_lambda.output_base64sha256
    runtime = "python3.11"

    vpc_config {
        security_group_ids = [aws_security_group.workflow_orchestrator_event_listener.id]
        subnet_ids = data.aws_subnets.workflow_manager_private_subnets.ids
    }

    environment {
        variables = {
          SNS_TOPIC_ARN = aws_sns_topic.workflow_orchestration_events_topic.arn
        }
    }
}

resource "aws_lambda_alias" "workflow_orchestration_event_listener_lambda_alias" {
    name = "wo_event_listener"
    description = "Workflow Orchestration Event Listener Function Alias."

    function_name = aws_lambda_function.workflow_orchestrator_event_listener_lambda.function_name
    function_version = "$LATEST"
}
