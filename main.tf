terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}


provider "aws" {
    access_key = var.aws_access_key
    region     = var.aws_region
    secret_key = var.aws_secret_key
}


data "aws_iam_policy_document" "lambda_assume_role_policy" {
    statement {
        actions = ["sts:AssumeRole"]
        effect = "Allow"

        principals {
            identifiers = ["lambda.amazonaws.com"]
            type        = "Service"
        }

    }
}

resource "aws_iam_role" "lambda_role" {
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
    name               = "lambda-role"
}


resource "aws_cloudwatch_event_rule" "every_minute" {
    description         = "Triggers every minute"
    name                = "every_minute"
    schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "trigger_hello_world_every_minute" {
    arn       = aws_lambda_function.hello_world.arn
    rule      = aws_cloudwatch_event_rule.every_minute.name
    target_id = "hello_world"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_trigger_hello_word" {
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.hello_world.function_name
    principal     = "events.amazonaws.com"
    source_arn    = aws_cloudwatch_event_rule.every_minute.arn
    statement_id  = "AllowExecutionFromCloudwatch"
}


resource "aws_s3_bucket" "lambda_bucket" {
    bucket = "hello-world-lambda-source-code"
}

resource "aws_s3_object" "lambda_hello_world" {
    bucket = aws_s3_bucket.lambda_bucket.id
    etag   = filemd5(data.archive_file.hello_world_function.output_path)
    key    = aws_lambda_function.hello_world.function_name
    source = data.archive_file.hello_world_function.output_path
}


data "archive_file" "hello_world_function" {
    output_path = "${path.module}/lambda/hello_world.zip"
    source_file = "${path.module}/lambda/hello_world/main.py"
    type        = "zip"
}

resource "aws_lambda_function" "hello_world" {
    filename         = data.archive_file.hello_world_function.output_path
    function_name    = "hello_world"
    handler          = "main.handler"
    role             = aws_iam_role.lambda_role.arn
    runtime          = "python3.9"
    source_code_hash = data.archive_file.hello_world_function.output_base64sha256
    timeout          = 10
}


data "aws_iam_policy_document" "lambda_loggable_role_policy" {
    statement {
        actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        effect    = "Allow"
        resources = ["arn:aws:logs:*:*:*"]
    }
}

resource "aws_iam_policy" "lambda_logging_policy" {
    name   = "lambda_logging_policy"
    policy = data.aws_iam_policy_document.lambda_loggable_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_logging_policy_attachment" {
    policy_arn = aws_iam_policy.lambda_logging_policy.arn
    role       = aws_iam_role.lambda_role.id
}

resource "aws_cloudwatch_log_group" "function_log_group" {
    name              = "/aws/lambda/${aws_lambda_function.hello_world.function_name}"
    retention_in_days = 7

    lifecycle {
        prevent_destroy = false
    }
}
