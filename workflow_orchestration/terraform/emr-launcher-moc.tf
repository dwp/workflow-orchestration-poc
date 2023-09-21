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

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_function" "emr_launcher" {
    filename = "../../../emr-launcher-release/emr-launcher-1.0.55.zip"
    function_name = "emr-launcher"
    role = aws_iam_role.iam_for_lambda.arn
    handler = "emr_launcher.handler.handler"
    runtime = "python3.7"

    timeout = 60

    environment {
        variables = {
            EMR_LAUNCHER_CONFIG_S3_BUCKET = aws_s3_bucket.emr_launcher_bucket.id
            EMR_LAUNCHER_CONFIG_S3_FOLDER = "emr/local"
            EMR_LAUNCHER_LOG_LEVEL = "INFO"
        }
    }
}

resource "aws_s3_bucket" "emr_launcher_bucket" {
    bucket = "emr-launcher-bucket"
}

resource "aws_s3_bucket_object" "cluster_config" {
  bucket = aws_s3_bucket.emr_launcher_bucket.id
  key    = "emr/local/cluster.yaml"
  source = "cluster_config/cluster.yaml"
}

resource "aws_s3_bucket_object" "configurations_config" {
  bucket = aws_s3_bucket.emr_launcher_bucket.id
  key    = "emr/local/configurations.yaml"
  source = "cluster_config/configurations.yaml"
}

resource "aws_s3_bucket_object" "instances_config" {
  bucket = aws_s3_bucket.emr_launcher_bucket.id
  key    = "emr/local/instances.yaml"
  source = "cluster_config/instances.yaml"
}

resource "aws_s3_bucket_object" "steps_config" {
  bucket = aws_s3_bucket.emr_launcher_bucket.id
  key    = "emr/local/steps.yaml"
  source = "cluster_config/steps.yaml"
}

resource "aws_secretsmanager_secret" "java_connection_password" {
  name = "connection-password"
}

variable "secrets" {
  default = {
    password = "password123"
  }
  type = map(string)
}

resource "aws_secretsmanager_secret_version" "java_connection_password" {
  secret_id = aws_secretsmanager_secret.java_connection_password.id
  secret_string = jsonencode(var.secrets)
}