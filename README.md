# AWS Infrastructure Configurations

This repository defines collections of AWS services that support our Data & Reporting processes.

The purpose of using Terraform to manage AWS deployments is to document the dependencies of each function, reduce manual deployment effort and improve reusability of AWS services.

## Creating a New Scheduled Lambda Function

1. Create a new directory under `lambda/` to contain your lambda function's source code
    ```
    mkdir lambda/new_lambda_function
    ```

2. Create the source code file called `main.py` under your newly created directory
    ```
    touch lamdba/new_lambda_function/main.py
    ```

3. Create the handler function that AWS calls as the entrypoint to the lambda
    ```python
    # lambda/new_lambda_function/main.py

    def handler(event, context):
      pass
    ```

4. Define the scheduled cloud function in `main.tf` as a module, passing in the required config variables alongside your lambda's input variables
    ```tf
    module "new_lambda_function" {
        source = "./modules/scheduled-lambda"

        # AWS Configuration & Dependencies
        aws_access_key    = var.aws_access_key
        aws_region        = var.aws_region
        aws_secret_key    = var.aws_secret_key

        lambdas_bucket_id = aws_s3_bucket.lambda_bucket.id
        lambda_role_arn   = aws_iam_role.lambda_role.arn

        # Function Parameters
        name     = "new_lambda_function"
        event    = {
            any = "variables"
            your = "function"
            expects = "to receive"
            in = "event payload"
        }
        schedule = {
            description = "Every 5 minutes"
            name        = "every_five_minutes"
            expression  = "rate(5 minutes)"
        }
    }
    ```
