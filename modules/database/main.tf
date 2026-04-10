# DynamoDB Table
resource "aws_dynamodb_table" "receipts" {
  name         = "receipts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "receiptID"
  range_key    = "date"

  attribute {
    name = "receiptID"
    type = "S"
  }
  attribute {
    name = "date"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}
