data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "workflow_orchestrator" {
  name               = "workflow_orchestrator"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "workflow_orchestrator_logging"
  path        = "/"
  description = "IAM policy for logging events for workflow orchestrator lambda."
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.workflow_orchestrator.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

data "aws_iam_policy_document" "xray_debugging" {
	statement {
    effect = "Allow"

		actions = [
				"xray:PutTraceSegments",
				"xray:PutTelemetryRecords"
		]

    resources = ["arn:aws:xray:*:*:*"]
	}
}

resource "aws_iam_policy" "lambda_xray" {
	name = "workflow_orchestrator_xray"
	path = "/"
	description = "Iam policy for debugging for workflow orchestrator lambda."
  policy = data.aws_iam_policy_document.xray_debugging.json
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role = aws_iam_role.workflow_orchestrator.name
  policy_arn = aws_iam_policy.lambda_xray.arn
}

data "aws_iam_policy_document" "vpc_deployment" {
	statement {
    effect = "Allow"

		actions = [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
		]

    resources = ["*"]
	}
}

resource "aws_iam_policy" "lambda_vpc_deployment" {
	name = "workflow_orchestrator_vpc_deployment"
	path = "/"
	description = "Iam policy to allow deploying workflow orchestrator lambda into a vpc."
  policy = data.aws_iam_policy_document.vpc_deployment.json
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_deployment" {
  role = aws_iam_role.workflow_orchestrator.name
  policy_arn = aws_iam_policy.lambda_vpc_deployment.arn
}

data "archive_file" "workflow_orchestrator_task_submitter_lambda" {
  type        = "zip"
  source_dir = "${path.module}/wo-task-submitter-lambda/"
  excludes = [
    "${path.module}/wo-task-submitter-lambda/test*"
  ]
  output_path = "workflow_orchestrator_task_submitter_lambda.zip"
}

resource "aws_security_group" "workflow_orchestrator" {
  name        = "workflow_orchestrator"
  description = "Workflow Orchestrator Lambda Security Group."
  vpc_id      = data.terraform_remote_state.azkaban.outputs.workflow_manager_vpc.vpc.id
  tags        = merge(local.tags, { Name = local.name })
}

resource "aws_lambda_function" "workflow_orchestrator_task_submitter_lambda" {
    filename = "${path.module}/workflow_orchestrator_task_submitter_lambda.zip"
    function_name = "workflow_orchestrator_task_submitter"
    role = aws_iam_role.workflow_orchestrator.arn
    handler = "handler.handler"
    source_code_hash = data.archive_file.workflow_orchestrator_task_submitter_lambda.output_base64sha256
    runtime = "python3.11"

    vpc_config {
        security_group_ids = [aws_security_group.workflow_orchestrator.id]
        subnet_ids = data.aws_subnets.workflow_manager_private_subnets.ids
    }

    # TODO: Some thought for appropriate value given time taken for downstream lambdas to complete
    timeout = 60
}
