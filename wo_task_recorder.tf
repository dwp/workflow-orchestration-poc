resource "aws_iam_role" "workflow_orchestrator_task_recorder" {
  name               = "wo_task_recorder"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "workflow_orchestrator_task_recorder_lambda_logs" {
  role       = aws_iam_role.workflow_orchestrator_task_recorder.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "workflow_orchestrator_task_recorder_lambda_xray" {
  role = aws_iam_role.workflow_orchestrator_task_recorder.name
  policy_arn = aws_iam_policy.lambda_xray.arn
}

resource "aws_iam_role_policy_attachment" "workflow_orchestrator_task_recorder_lambda_vpc_deployment" {
  role = aws_iam_role.workflow_orchestrator_task_recorder.name
  policy_arn = aws_iam_policy.lambda_vpc_deployment.arn
}

data "archive_file" "workflow_orchestrator_task_recorder_lambda" {
  type        = "zip"
  source_dir = "${path.module}/wo-task-recorder-lambda/"
  excludes = [
    "${path.module}/wo-task-recorder-lambda/test*"
  ]
  output_path = "workflow_orchestrator_task_recorder_lambda.zip"
}

resource "aws_security_group" "workflow_orchestrator_task_recorder" {
  name        = "wo_task_recorder"
  description = "Workflow Orchestrator Task recorder Lambda Security Group."
  vpc_id      = data.terraform_remote_state.azkaban.outputs.workflow_manager_vpc.vpc.id
  tags        = merge(local.tags, { Name = local.name })
}

resource "aws_lambda_function" "workflow_orchestrator_task_recorder_lambda" {
    filename = "${path.module}/workflow_orchestrator_task_recorder_lambda.zip"
    function_name = "workflow_orchestrator_task_recorder"
    role = aws_iam_role.workflow_orchestrator_task_recorder.arn
    handler = "handler.handler"
    source_code_hash = data.archive_file.workflow_orchestrator_task_recorder_lambda.output_base64sha256
    runtime = "python3.11"

    vpc_config {
        security_group_ids = [aws_security_group.workflow_orchestrator_task_recorder.id]
        subnet_ids = data.aws_subnets.workflow_manager_private_subnets.ids
    }

    # TODO: Some thought for appropriate value given time taken for downstream lambdas to complete
    timeout = 60
}

resource "aws_lambda_permission" "sns_to_workflow_orchestrator_task_recorder" {
    statement_id = "AllowSNSLambdaExecution"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.workflow_orchestrator_task_recorder_lambda.function_name
    principal = "sns.amazonaws.com"
    source_arn = aws_sns_topic.workflow_orchestration_events_topic.arn
}