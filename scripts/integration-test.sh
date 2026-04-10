#!/bin/bash
set -e

echo "Starting Integration Probe..."

# Check if DynamoDB Table is Active
TABLE_STATUS=$(aws dynamodb describe-table --table-name "$TABLE_NAME" --query 'Table.TableStatus' --output text)

if [ "$TABLE_STATUS" == "ACTIVE" ]; then
  echo "✅ DynamoDB Table $TABLE_NAME is online and accepting requests."
else
  echo "❌ DynamoDB Table is $TABLE_STATUS"
  exit 1
fi

echo "Integration Probe Successful!"
