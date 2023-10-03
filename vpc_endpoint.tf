resource "aws_security_group" "workflow_orchestrator_service_endpoint" {
  name        = "workflow_orchestrator_service_endpoint"
  description = "Control access to the Workflow Orchestrator VPC Endpoint"
  vpc_id      = data.terraform_remote_state.azkaban.outputs.workflow_manager_vpc.vpc.id
  tags        = merge(local.tags, { Name = local.name })

  ingress {
    description = "Azkaban to Workflow Orchesrator overport 443."
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = [data.terraform_remote_state.azkaban.outputs.azkaban_webserver_sg.id]
  }
}

resource "aws_vpc_endpoint" "workflow_orchestrator_service" {
  vpc_id              = data.terraform_remote_state.azkaban.outputs.workflow_manager_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.execute-api"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.workflow_orchestrator_service_endpoint.id]
  subnet_ids          = data.aws_subnets.workflow_manager_private_subnets.ids
  private_dns_enabled = true
  tags                = merge(local.tags, { Name = "workflow-orchestration-service" })
}