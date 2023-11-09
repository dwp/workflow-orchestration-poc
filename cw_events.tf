resource "aws_cloudwatch_event_bus" "workflow_orchestration_event_listener_event_bus" {
	name = "workflow_orchestration_bus"
}

resource "aws_schemas_discoverer" "workflow_orchestration_test_schemas" {
	source_arn  = aws_cloudwatch_event_bus.workflow_orchestration_event_listener_event_bus.arn
  	description = "Auto discover test event schemas."
}

resource "aws_cloudwatch_event_rule" "emr_cluster_state_change" {
  	name        = "emr_cluster_state_change"
  	description = "EMR Cluster State Change Events"

	event_bus_name = aws_cloudwatch_event_bus.workflow_orchestration_event_listener_event_bus.name
  	event_pattern = jsonencode({		
  		source: ["test.emr"],
  		detail-type: ["EMR Cluster State Change"],
  		detail: {
    		state: ["RUNNING", "WAITING", "TERMINATED", "TERMINATED_WITH_ERRORS"]
  		}
  	})
}

resource "aws_lambda_permission" "allow_events_to_workflow_orchestration_event_listener" {
	statement_id  = "AllowExecutionFromCloudWatch"
  	action        = "lambda:InvokeFunction"
  	function_name = aws_lambda_function.workflow_orchestrator_event_listener_lambda.function_name
  	principal     = "events.amazonaws.com"
  	source_arn    = aws_cloudwatch_event_rule.emr_cluster_state_change.arn
  	qualifier     = aws_lambda_alias.workflow_orchestration_event_listener_lambda_alias.name
}

resource "aws_cloudwatch_event_target" "workflow_orchhestration_event_listener_lambda" {
  	arn       = aws_lambda_alias.workflow_orchestration_event_listener_lambda_alias.arn
	rule      = aws_cloudwatch_event_rule.emr_cluster_state_change.name
  	target_id = "SentToWorkflowOrchestrationEventListenerLambda"
	event_bus_name = aws_cloudwatch_event_bus.workflow_orchestration_event_listener_event_bus.name
}