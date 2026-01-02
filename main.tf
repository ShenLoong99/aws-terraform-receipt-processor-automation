provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ServerlessReceiptProcessor"
      Environment = "Development"
      Owner       = "ShenLoong"
      ManagedBy   = "Terraform"
      CostCenter  = "Research-and-Development"
    }
  }
}

# Add this local variable at the top of main.tf
locals {
  lambda_name = "ReceiptProcessor"
}

# Automatically get the current region from the provider
data "aws_region" "current" {}

# DynamoDB Table
resource "aws_dynamodb_table" "receipts" {
  name         = "receipts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "receiptID"
  range_key    = "date"

  attribute {
    name = "receiptID"
    type = "S"
  }
  attribute {
    name = "date"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

# S3 Bucket
resource "aws_s3_bucket" "receipt_storage" {
  # This creates: receipt-system-a1b2c3d4 automatically
  bucket        = "receipt-system-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_lifecycle_configuration" "receipt_lifecycle" {
  bucket = aws_s3_bucket.receipt_storage.id

  rule {
    id     = "delete-old-receipts-demo"
    status = "Enabled"

    # Target only the receipts folder
    filter {
      prefix = "incoming/"
    }

    # Delete objects 1 day after creation (shortest possible time)
    expiration {
      days = 1
    }

    # Clean up unfinished uploads to save space
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# Zip the Lambda Code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/src/lambda_function.zip"
}

# Lambda Function
resource "aws_lambda_function" "processor" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = local.lambda_name # Use local variable
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  memory_size   = 512 # Minimum RAM (cheapest/free)
  timeout       = 180

  # DYNAMIC INJECTION:
  environment {
    variables = {
      # Pulls name directly from the resource created above
      DYNAMODB_TABLE = aws_dynamodb_table.receipts.name
      # Pulls bucket name directly
      RECEIPT_BUCKET = aws_s3_bucket.receipt_storage.id
      # Pulls region from the data source
      AWS_REGION_NAME = data.aws_region.current.name
      # Pulls from your manual export
      SES_SENDER_EMAIL    = var.user_email
      SES_RECIPIENT_EMAIL = var.user_email
    }
  }
}

# S3 Trigger Permission
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.receipt_storage.arn
}

# S3 Bucket Notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.receipt_storage.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "incoming/"
  }
  depends_on = [aws_lambda_permission.allow_s3]
}

# SES Identity (Needs manual email verification after apply)
resource "aws_ses_email_identity" "email" {
  email = var.user_email
}

# Create "incoming/" folder in S3 Bucket
resource "aws_s3_object" "incoming_folder" {
  bucket       = aws_s3_bucket.receipt_storage.id
  key          = "incoming/" # This creates the folder prefix
  content_type = "application/x-directory"
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  # The name MUST follow this exact pattern for Lambda to use it
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = 7 # Automatically deletes old logs to save costs
}