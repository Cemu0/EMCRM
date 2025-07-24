import boto3
from botocore.config import Config
from app.config import settings

dynamodb = boto3.resource(
    'dynamodb',
    region_name=settings.database.aws_region,
    endpoint_url=settings.database.dynamodb_endpoint,
    aws_access_key_id=settings.database.aws_access_key_id,
    aws_secret_access_key=settings.database.aws_secret_access_key,
    config=Config(
        retries={'max_attempts': settings.database.max_retries, 'mode': 'standard'},
        connect_timeout=settings.database.connect_timeout,
        read_timeout=settings.database.read_timeout,
        max_pool_connections=settings.database.max_pool_connections
    )
)


MAIN_TABLE_NAME = settings.database.main_table_name
EMAIL_TABLE_NAME = settings.database.email_table_name

try:
    table = dynamodb.Table(MAIN_TABLE_NAME) 
except dynamodb.meta.client.exceptions.ResourceNotFoundException:
    raise ValueError(f"DynamoDB table {MAIN_TABLE_NAME} does not exist. Please create it first.")

try:
    email_table = dynamodb.Table(EMAIL_TABLE_NAME) 
except dynamodb.meta.client.exceptions.ResourceNotFoundException:
    raise ValueError(f"DynamoDB table {EMAIL_TABLE_NAME} does not exist. Please create it first.")