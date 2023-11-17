resource "aws_dynamodb_table" "workflow_orchestration_tasks_db" {
    name = "WorkflowOrchestrationTasks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "TaskType"
    range_key = "TaskId"

    attribute {
      name = "TaskType"
      type = "S"
    }

    attribute {
      name = "TaskId"
      type = "S"
    }
}