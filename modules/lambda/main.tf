# Zip the Lambda Code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/src/lambda_function.zip"
}

# Lambda Function
resource "aws_lambda_function" "processor" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = var.lambda_name # Use local variable
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  memory_size   = 512 # Minimum RAM (cheapest/free)
  timeout       = 180

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  # DYNAMIC INJECTION:
  environment {
    variables = {
      # Pulls name directly from the resource created above
      DYNAMODB_TABLE = var.db_name
      # Pulls bucket ID directly
      RECEIPT_BUCKET = var.bucket_id
      # Pulls region from the data source
      AWS_REGION_NAME = var.aws_region
      # Pulls from your manual export
      SES_SENDER_EMAIL    = var.user_email
      SES_RECIPIENT_EMAIL = var.user_email
    }
  }
}

# Create the SQS Queue to act as the DLQ
resource "aws_sqs_queue" "lambda_dlq" {
  name                    = "receipt-processing-lambda-dlq"
  sqs_managed_sse_enabled = true
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "receipt_processor_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# SES Identity (Needs manual email verification after apply)
resource "aws_ses_email_identity" "email" {
  email = var.user_email
}

# IAM Policy for Lambda (Permissions)
resource "aws_iam_policy" "lambda_policy" {
  name        = "receipt_processor_policy"
  description = "Permissions for receipt processing"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "${var.bucket_arn}/*"
      },
      {
        Action   = ["textract:AnalyzeExpense"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["dynamodb:PutItem"]
        Effect   = "Allow"
        Resource = var.db_arn
      },
      {
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Effect   = "Allow"
        Resource = aws_ses_email_identity.email.arn
      },
      {
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect = "Allow"
        # Reference the Log Group directly
        Resource = "${aws_cloudwatch_log_group.lambda_logs.arn}:*"
      },
      {
        Action   = ["sqs:SendMessage"]
        Effect   = "Allow"
        Resource = aws_sqs_queue.lambda_dlq.arn
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  # The name MUST follow this exact pattern for Lambda to use it
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 7 # Automatically deletes old logs to save costs
}
