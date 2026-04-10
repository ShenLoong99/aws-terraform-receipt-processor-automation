output "region" {
  description = "The AWS region being used"
  value       = var.aws_region
}

output "bucket_id" {
  description = "The ID of the S3 bucket created"
  value       = module.storage.bucket_id
}

output "lambda_function_name" {
  description = "The name of the Lambda function created"
  value       = module.lambda.lambda_function_name
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = module.database.db_name
}
