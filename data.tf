data "aws_subnets" "workflow_manager_private_subnets" {
  filter {
    name  = "vpc-id"
    values = [
        data.terraform_remote_state.azkaban.outputs.workflow_manager_vpc.vpc.id
    ]
  }

  tags = {
    Name = "workflow-manager-private*"
  }
}