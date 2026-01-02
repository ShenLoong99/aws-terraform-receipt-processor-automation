variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-southeast-1"
}

variable "user_email" {
  description = "The verified email for SES sending and receiving"
  type        = string
}

# variable "bucket_name" {
#   description = "Unique name for your S3 bucket"
#   type        = string
# }