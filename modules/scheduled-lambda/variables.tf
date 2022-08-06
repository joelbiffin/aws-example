# AWS Config Variables
variable "aws_access_key" { type = string }
variable "aws_secret_key" { type = string }
variable "aws_region" { type = string }

# Resource Dependencies
variable "lambdas_bucket_id" { type = string }
variable "lambda_role_arn" { type = string }

# Input variables
variable "name" { type = string }
variable "schedule" {
    type = object({
        name = string
        description = string
        expression = string
    })
}
variable "event" { type = map(any) }
