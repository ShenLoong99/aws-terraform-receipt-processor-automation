output "lambda_function_name" {
  description = "The name of the Lambda function created"
  value       = aws_lambda_function.processor.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function created"
  value       = aws_lambda_function.processor.arn
}
