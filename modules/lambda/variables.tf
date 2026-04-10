variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "user_email" {
  description = "The verified email for SES sending and receiving"
  type        = string
}

variable "lambda_name" {
  description = "Name for the Lambda function"
  type        = string
}

variable "db_name" {
  description = "Name for the DynamoDB table"
  type        = string
}

variable "bucket_id" {
  description = "ID for your S3 bucket"
  type        = string
}

variable "db_arn" {
  description = "ARN for the DynamoDB table"
  type        = string
}

variable "bucket_arn" {
  description = "ARN for the S3 bucket"
  type        = string
}
