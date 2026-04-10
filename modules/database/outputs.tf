output "db_name" {
  description = "The name of the DynamoDB table created"
  value       = aws_dynamodb_table.receipts.name
}

output "db_arn" {
  description = "The ARN of the DynamoDB table created"
  value       = aws_dynamodb_table.receipts.arn
}
