import boto3
import os
from botocore.config import Config

# Get configuration from environment variables or use defaults
region = os.getenv('AWS_REGION', 'us-west-2')
endpoint_url = os.getenv('DYNAMODB_ENDPOINT', 'http://localhost:8000')
access_key = os.getenv('AWS_ACCESS_KEY_ID', 'dummy')
secret_key = os.getenv('AWS_SECRET_ACCESS_KEY', 'dummy')

dynamodb = boto3.resource(
    'dynamodb',
    region_name=region,
    endpoint_url=endpoint_url,
    aws_access_key_id=access_key,
    aws_secret_access_key=secret_key,
    config=Config(
        retries={'max_attempts': 2, 'mode': 'standard'},
        connect_timeout=5,
        read_timeout=10,
        max_pool_connections=10
    )
)


MAIN_TABLE_NAME = "crm_data"
EMAIL_TABLE_NAME = "email_data"

try:
    table = dynamodb.Table(MAIN_TABLE_NAME) 
except dynamodb.meta.client.exceptions.ResourceNotFoundException:
    raise ValueError(f"DynamoDB table {MAIN_TABLE_NAME} does not exist. Please create it first.")

try:
    email_table = dynamodb.Table(EMAIL_TABLE_NAME) 
except dynamodb.meta.client.exceptions.ResourceNotFoundException:
    raise ValueError(f"DynamoDB table {EMAIL_TABLE_NAME} does not exist. Please create it first.")