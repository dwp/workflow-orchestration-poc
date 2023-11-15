data "aws_iam_policy_document" "sns_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "sns_success_feedback" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutMetricFilter",
      "logs:PutRetentionPolicy",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "sns_success_feedback" {
  name        = "topic_success_feedback"
  path        = "/"
  description = "IAM policy for logging successful event submissions to SNS topic."
  policy      = data.aws_iam_policy_document.sns_success_feedback.json
}

data "aws_iam_policy_document" "sns_failure_feedback" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutMetricFilter",
      "logs:PutRetentionPolicy",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "sns_failure_feedback" {
  name        = "topic_failure_feedback"
  path        = "/"
  description = "IAM policy for logging failed event submissions to SNS topic."
  policy      = data.aws_iam_policy_document.sns_failure_feedback.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
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

data "aws_iam_policy_document" "publish_to_sns_events_topic" {
	statement {
    effect = "Allow"

		actions = [
        "sns:Publish"
		]

    resources = [aws_sns_topic.workflow_orchestration_events_topic.arn]
	}
}

resource "aws_iam_policy" "lambda_to_sns" {
	name = "workflow_orchestrator_lambda_to_sns"
	path = "/"
	description = "Iam policy to allow workflow orchestrator lambdas to publish to workflow orchestration Events SNS topic."
  policy = data.aws_iam_policy_document.publish_to_sns_events_topic.json
}
