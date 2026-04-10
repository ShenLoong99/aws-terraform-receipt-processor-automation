#!/bin/bash
set -e

echo "Starting Infrastructure Health Check..."

# 1. Verify S3 Bucket Accessibility
aws s3 ls "s3://$BUCKET_NAME" > /dev/null
echo "✅ S3 Bucket $BUCKET_NAME is reachable."

# 2. Verify Lambda State
LAMBDA_STATE=$(aws lambda get-function --function-name "$LAMBDA_NAME" --query 'Configuration.State' --output text)

if [ "$LAMBDA_STATE" == "Active" ]; then
  echo "✅ Lambda Function $LAMBDA_NAME is Active."
else
  echo "❌ Lambda Function is in state: $LAMBDA_STATE"
  exit 1
fi

echo "Infrastructure Health Check Passed!"
