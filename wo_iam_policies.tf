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
  description = "IAM policy for logging events for workflow orchestrator lambdas."
  policy      = data.aws_iam_policy_document.lambda_logging.json
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
	description = "Iam policy to allow deploying workflow orchestrator lambdas into a vpc."
  policy = data.aws_iam_policy_document.vpc_deployment.json
}
