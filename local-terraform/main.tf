provider "aws" {
    region = "us-east-1"
}

resource "aws_acm_certificate" "cert" {
    domain_name = "workflow.localhost"
    validation_method = "DNS"
}

resource "aws_route53_zone" "primary_domain" {
    name = "localhost"
}

resource "aws_apigatewayv2_domain_name" "workflow_orchestration" {
    domain_name = "workflow.localhost"
    domain_name_configuration {
        certificate_arn = aws_acm_certificate.cert.arn
        endpoint_type = "REGIONAL"
        security_policy = "TLS_1_2"
    }
}

resource "aws_route53_record" "workflow_orchestration" {
    zone_id = aws_route53_zone.primary_domain.zone_id
    name = "workflow.localhost"
    type = "A"
    
    alias {
        name = aws_apigatewayv2_domain_name.workflow_orchestration.domain_name_configuration[0].target_domain_name
        zone_id = aws_apigatewayv2_domain_name.workflow_orchestration.domain_name_configuration[0].hosted_zone_id
        evaluate_target_health = false
    }
}

resource "aws_apigatewayv2_api" "workflow_orchestration" {
    name = "workflow_orchestration_api"
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "workflow_orchestration" {
    api_id = aws_apigatewayv2_api.workflow_orchestration.id
    
    integration_type = "AWS_PROXY"
    integration_method = "POST"
    integration_uri = "arn:aws:lambda:us-east-1:000000000000:function:workflow_orchestrator"
}

resource "aws_apigatewayv2_route" "submit_task" {
    api_id = aws_apigatewayv2_api.workflow_orchestration.id
    route_key = "POST /submit/emr_launcher"

    target = "integrations/${aws_apigatewayv2_integration.workflow_orchestration.id}" 
}

resource "aws_apigatewayv2_stage" "workflow_orchestration" {
    api_id = aws_apigatewayv2_api.workflow_orchestration.id
    name = "local"
}

resource "aws_apigatewayv2_api_mapping" "workflow_orchestration" {
    api_id = aws_apigatewayv2_api.workflow_orchestration.id
    domain_name = aws_apigatewayv2_domain_name.workflow_orchestration.id
    stage = aws_apigatewayv2_stage.workflow_orchestration.id
}
