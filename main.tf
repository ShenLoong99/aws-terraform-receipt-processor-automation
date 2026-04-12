# This Terraform configuration sets up an automated receipt processing system using AWS services.

# database module (DynamoDB)
module "database" {
  source = "./modules/database"
}

# storage module (S3)
module "storage" {
  source               = "./modules/storage"
  lambda_function_name = module.lambda.lambda_function_name
  lambda_function_arn  = module.lambda.lambda_function_arn
}

# lambda module (Lambda) test
module "lambda" {
  source      = "./modules/lambda"
  aws_region  = var.aws_region
  user_email  = var.user_email
  lambda_name = var.lambda_name
  db_name     = module.database.db_name
  bucket_id   = module.storage.bucket_id
  db_arn      = module.database.db_arn
  bucket_arn  = module.storage.bucket_arn
}
