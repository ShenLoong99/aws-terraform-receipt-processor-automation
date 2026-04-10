output "bucket_id" {
  description = "The ID of the S3 bucket created"
  value       = aws_s3_bucket.receipt_storage.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket created"
  value       = aws_s3_bucket.receipt_storage.arn
}
