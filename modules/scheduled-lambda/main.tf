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


resource "aws_cloudwatch_event_rule" "trigger_schedule" {
    description         = var.schedule.description
    name                = var.schedule.name
    schedule_expression = var.schedule.expression
}

resource "aws_cloudwatch_event_target" "function_trigger" {
    arn       = aws_lambda_function.function.arn
    input     = jsonencode(var.event)
    rule      = aws_cloudwatch_event_rule.trigger_schedule.name
    target_id = var.name
}

resource "aws_lambda_permission" "allow_cloudwatch_to_trigger_hello_word" {
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.function.function_name
    principal     = "events.amazonaws.com"
    source_arn    = aws_cloudwatch_event_rule.trigger_schedule.arn
    statement_id  = "AllowExecutionFromCloudwatch"
}

resource "aws_s3_object" "source_code_storage" {
    bucket = var.lambdas_bucket_id
    etag   = filemd5(data.archive_file.source_code_zip.output_path)
    key    = aws_lambda_function.function.function_name
    source = data.archive_file.source_code_zip.output_path
}

data "archive_file" "source_code_zip" {
    output_path = "${path.root}/lambda/${var.name}.zip"
    source_file = "${path.root}/lambda/${var.name}/main.py"
    type        = "zip"
}

resource "aws_lambda_function" "function" {
    filename         = data.archive_file.source_code_zip.output_path
    function_name    = var.name
    handler          = "main.handler"
    role             = var.lambda_role_arn
    runtime          = "python3.9"
    source_code_hash = data.archive_file.source_code_zip.output_base64sha256
    timeout          = 10
}

resource "aws_cloudwatch_log_group" "function_log_group" {
    name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
    retention_in_days = 7

    lifecycle {
        prevent_destroy = false
    }
}
