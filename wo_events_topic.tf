resource "aws_iam_role" "lambda_to_sns_success_feedback_role" {
    name = "sns_lambda_success_feedback"
    assume_role_policy = data.aws_iam_policy_document.sns_assume_role.json
}

resource "aws_iam_role_policy_attachment" "workflow_orchestration_events_topic_success_feedback" {
  role = aws_iam_role.lambda_to_sns_success_feedback_role.name
  policy_arn = aws_iam_policy.sns_success_feedback.arn
}

resource "aws_iam_role" "lambda_to_sns_failure_feedback_role" {
    name = "sns_lambda_failure_feedback"
    assume_role_policy = data.aws_iam_policy_document.sns_assume_role.json
}

resource "aws_iam_role_policy_attachment" "workflow_orchestration_events_topic_failure_feedback" {
  role = aws_iam_role.lambda_to_sns_failure_feedback_role.name
  policy_arn = aws_iam_policy.sns_failure_feedback.arn
}

resource "aws_sns_topic" "workflow_orchestration_events_topic" {
    name = "workflow_orchestration_task_events.fifo"
    fifo_topic = true
    application_success_feedback_role_arn = aws_iam_role.lambda_to_sns_success_feedback_role.arn
    application_failure_feedback_role_arn = aws_iam_role.lambda_to_sns_failure_feedback_role.arn
    lambda_success_feedback_sample_rate = 100
}

resource "aws_sqs_queue" "events_queue_for_testing" {
    name = "workflow_orchestration_task_events.fifo"
    fifo_queue = true
    message_retention_seconds = 60
}

data "aws_iam_policy_document" "sns_to_sqs" {
    statement {
        sid    = "First"
        effect = "Allow"

        principals {
            type        = "*"
            identifiers = ["*"]
        }

        actions   = ["sqs:SendMessage"]
        resources = [aws_sqs_queue.events_queue_for_testing.arn]

        condition {
            test     = "ArnEquals"
            variable = "aws:SourceArn"
            values   = [aws_sns_topic.workflow_orchestration_events_topic.arn]
        }
  }
}

resource "aws_sqs_queue_policy" "event_queue_for_testing_policy" {
    queue_url = aws_sqs_queue.events_queue_for_testing.id
    policy = data.aws_iam_policy_document.sns_to_sqs.json
}

resource "aws_sns_topic_subscription" "event_queue_subscription" {
    topic_arn = aws_sns_topic.workflow_orchestration_events_topic.arn
    protocol = "sqs"
    endpoint = aws_sqs_queue.events_queue_for_testing.arn
}
