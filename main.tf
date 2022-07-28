terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}


provider "aws" {
    access_key = var.access_key
    region     = var.aws_region
    secret_key = var.secret_key
}


data "aws_iam_policy_document" "lambda_assume_role_policy" {
    statement {
        actions = ["sts.AssumeRole"]
        effect = "Allow"

        principals {
            identifiers = ["lambda.amazonaws.com"]
            type = "Service"
        }
    }
}

resource "aws_iam_role" "lambda_role" {
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
    name               = "lambda-lambdaRole-waf"
}


resource "aws_cloudwatch_event_rule" "every_minute" {
    description         = "Triggers every minute"
    name                = "every_minute"
    schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "trigger_hello_world_every_minute" {
    arn       = aws_lambda_function.lambda.arn
    rule      = aws_cloudwatch_event_rule.every_minute.name
    target_id = "hello_world"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_trigger_hello_word" {
    action        = "lamdba:InvokeFunction"
    function_name = aws_lambda_function.hello_world.function_name
    principal     = "events.amazonaws.com"
    source_arn    = aws_cloudwatch_event_rule.every_minute.arn
    statement_id  = "AllowExecutionFromCloudwatch"
}


resource "aws_s3_bucket" "lamdba_bucket" {
    bucket = "lambda-source-code"
}

resource "aws_s3_object" "lambda_hello_world" {
    bucket = aws_s3_bucket.lambda_bucket.id
    etag   = filemd5(data.archive_file.hello_world_function.output_path)
    key    = aws_lambda_function.function_name
    source = data.archive_file.hello_world_function.output_path
}


data "archive_file" "hello_world_function" {
    output_path = "${path.module}/lambda/hello_world.zip"
    source      = "${path.module}/lambda/hello_world/main.py"
    type        = "zip"
}

resource "aws_lambda_function" "hello_world" {
    filename         = "hello_world.zip"
    function_name    = "hello_world"
    handler          = "main.handler"
    role             = aws_iam_role.lambda_role.arn
    runtime          = "python3.9"
    source_code_hash = data.archive_file.hello_world_function.output_base64sha256
    timeout          = 10
}
