resource "aws_iam_role" "workflow_orchestrator_event_listener" {
  name               = "wo_event_listener"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
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
}

resource "aws_lambda_alias" "workflow_orchestration_event_listener_lambda_alias" {
    name = "wo_event_listener"
    description = "Workflow Orchestration Event Listener Function Alias."

    function_name = aws_lambda_function.workflow_orchestrator_event_listener_lambda.function_name
    function_version = "$LATEST"
}