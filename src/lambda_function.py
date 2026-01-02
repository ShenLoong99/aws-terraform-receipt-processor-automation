import boto3
import os
import uuid
from datetime import datetime

# AUTO-PULL from Environment (Provisioned by Terraform)
REGION = os.environ.get('AWS_REGION_NAME', 'us-east-1')
TABLE_NAME = os.environ.get('DYNAMODB_TABLE')
SENDER = os.environ.get('SES_SENDER_EMAIL')

# Initialize clients using the dynamic region
textract = boto3.client('textract', region_name=REGION)
dynamodb = boto3.resource('dynamodb', region_name=REGION)
ses = boto3.client('ses', region_name=REGION)

def extract_receipt_data(bucket, key):
    # Textract processes the file found in the bucket
    response = textract.analyze_expense(
        Document={'S3Object': {'Bucket': bucket, 'Name': key}}
    )
    
    # We iterate through the 'ExpenseDocuments' to find fields 
    # like TOTAL, vendor name, and date.
    data = {}
    for doc in response['ExpenseDocuments']:
        for field in doc['SummaryFields']:
            field_type = field['Type']['Text']
            if field_type in ['TOTAL', 'VENDOR_NAME', 'DATE']:
                data[field_type] = field['ValueDetection']['Text']
    return data

def lambda_handler(event, context):
    print(f"Received event: {event}")
    # The S3 Trigger automatically provides the bucket and file name
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    print(f"Processing file: {key} from bucket: {bucket}")

    try: 
        # Extract data using the helper function
        print("Starting Textract AnalyzeExpense...")
        extracted = extract_receipt_data(bucket, key)
        print(f"Extracted data: {extracted}")
        
        # Save to DynamoDB
        table = dynamodb.Table(TABLE_NAME)
        print(f"Saving to DynamoDB table: {TABLE_NAME}")
        receipt_id = str(uuid.uuid4())
        table.put_item(Item={
            'receiptID': receipt_id,
            'date': extracted.get('DATE', str(datetime.now().date())),
            'vendor': extracted.get('VENDOR_NAME', 'Unknown'),
            'total': extracted.get('TOTAL', '0.00')
        })
        print("Successfully saved to DynamoDB.")
        
        # Send Summary Email
        body = f"New Receipt Processed!\nVendor: {extracted.get('VENDOR_NAME')}\nTotal: {extracted.get('TOTAL')}"
        ses.send_email(
            Source=SENDER,
            Destination={'ToAddresses': [SENDER]},
            Message={'Subject': {'Data': 'Receipt Summary'}, 'Body': {'Text': {'Data': body}}}
        )

    except Exception as e:
        print(f"ERROR: Processing failed. Reason: {str(e)}") # Detailed error logging
        raise e