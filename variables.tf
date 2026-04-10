variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "user_email" {
  description = "The verified email for SES sending and receiving"
  type        = string
}

variable "lambda_name" {
  description = "Name for the Lambda function"
  type        = string
  default     = "ReceiptProcessor"
}

# variable "bucket_name" {
#   description = "Unique name for your S3 bucket"
#   type        = string
# }
