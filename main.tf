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


# Lambda Functions

module "hello_world_scheduled_lambda" {
    source = "./modules/scheduled-lambda"

    # AWS Configuration & Dependencies
    aws_access_key    = var.aws_access_key
    aws_region        = var.aws_region
    aws_secret_key    = var.aws_secret_key

    lambdas_bucket_id = aws_s3_bucket.lambda_bucket.id
    lambda_role_arn   = aws_iam_role.lambda_role.arn


    # Function Parameters
    name     = "hello_world"
    event    = {
        a = "bar"
    }
    schedule = {
        description = "Every 5 minutes"
        name        = "every_five_minutes"
        expression  = "rate(5 minutes)"
    }
}


# Permissions & Shared Dependencies

resource "aws_s3_bucket" "lambda_bucket" {
    bucket = "hello-world-lambda-source-code"
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
