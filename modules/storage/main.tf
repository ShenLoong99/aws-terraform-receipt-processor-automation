# S3 Bucket
resource "aws_s3_bucket" "receipt_storage" {
  # This creates: receipt-system-a1b2c3d4 automatically
  bucket        = "receipt-system-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# S3 Bucket Policy to allow Lambda to read from the bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Lifecycle configuration to auto-delete old receipts
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

    # Abort failed uploads after 7 days to save money
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # If you enabled versioning, delete non-current versions after 7 days
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "versioning_receipt_storage" {
  bucket = aws_s3_bucket.receipt_storage.id
  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.receipt_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "receipt_storage_access" {
  bucket = aws_s3_bucket.receipt_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Trigger Permission
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.receipt_storage.arn
}

# S3 Bucket Notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.receipt_storage.id

  lambda_function {
    lambda_function_arn = var.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "incoming/"
  }
  depends_on = [aws_lambda_permission.allow_s3]
}

# Create "incoming/" folder in S3 Bucket
resource "aws_s3_object" "incoming_folder" {
  bucket       = aws_s3_bucket.receipt_storage.id
  key          = "incoming/" # This creates the folder prefix
  content_type = "application/x-directory"
}
