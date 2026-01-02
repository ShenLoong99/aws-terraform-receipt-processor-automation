output "region" {
  description = "The AWS region being used"
  value       = var.aws_region
}

output "bucket_name" {
  description = "The name of the S3 bucket created"
  value       = aws_s3_bucket.receipt_storage.id
}

output "lambda_function_name" {
  value = aws_lambda_function.processor.function_name
}