import boto3
from typing import Optional, Any
from botocore.config import Config
from app.config import settings

# Determine environment and configure DynamoDB connection accordingly
if settings.app.production:
    # Production: Use IAM roles, no explicit credentials, no local endpoint
    dynamodb = boto3.resource(
        'dynamodb',
        region_name=settings.database.aws_region,
        config=Config(
            retries={'max_attempts': settings.database.max_retries, 'mode': 'standard'},
            connect_timeout=settings.database.connect_timeout,
            read_timeout=settings.database.read_timeout,
            max_pool_connections=settings.database.max_pool_connections
        )
    )
else:
    # Development: Use dummy credentials for local DynamoDB
    dynamodb = boto3.resource(
        'dynamodb',
        region_name=settings.database.aws_region,
        endpoint_url=settings.database.dynamodb_endpoint,
        aws_access_key_id="dummy",
        aws_secret_access_key="dummy",
        config=Config(
            retries={'max_attempts': settings.database.max_retries, 'mode': 'standard'},
            connect_timeout=settings.database.connect_timeout,
            read_timeout=settings.database.read_timeout,
            max_pool_connections=settings.database.max_pool_connections
        )
    )

MAIN_TABLE_NAME = settings.database.main_table_name
EMAIL_TABLE_NAME = settings.database.email_table_name

def get_table(table_name: str) -> Any:
    """Get a DynamoDB table object with proper error handling"""
    try:
        return dynamodb.Table(table_name)  # type: ignore
    except Exception as e:
        if settings.app.production:
            raise ValueError(f"DynamoDB table '{table_name}' does not exist in production. Please ensure Terraform has created it. Error: {e}")
        else:
            raise ValueError(f"DynamoDB table '{table_name}' not found in development environment. Please run table creation first. Error: {e}")

def get_main_table():
    """Get the main CRM table"""
    return get_table(MAIN_TABLE_NAME)

def get_email_table():
    """Get the email table"""
    return get_table(EMAIL_TABLE_NAME)

# For backward compatibility, create table objects
# In production, these will fail if tables don't exist (which is expected)
# In development, these will be None if tables haven't been created yet
table: Optional[Any] = None
email_table: Optional[Any] = None

try:
    table = dynamodb.Table(MAIN_TABLE_NAME)  # type: ignore
    email_table = dynamodb.Table(EMAIL_TABLE_NAME)  # type: ignore
except Exception:
    # Tables don't exist yet - this is normal in development before table creation
    # In production, this would indicate a configuration problem
    if settings.app.production:
        print(f"Warning: Could not initialize DynamoDB tables in production environment. Tables may not exist.")
    table = None
    email_table = None