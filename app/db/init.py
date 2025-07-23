from .session import dynamodb, MAIN_TABLE_NAME, EMAIL_TABLE_NAME
import time
import os
from botocore.exceptions import ClientError
from botocore.config import Config

# Timeout settings
CONNECTION_TIMEOUT = int(os.getenv('DB_CONNECTION_TIMEOUT', '5'))


def create_tables():
    try:
        dynamodb.create_table(
            TableName=MAIN_TABLE_NAME,
            KeySchema=[
                {'AttributeName': 'PK', 'KeyType': 'HASH'},
                {'AttributeName': 'SK', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'PK', 'AttributeType': 'S'},
                {'AttributeName': 'SK', 'AttributeType': 'S'},
                {'AttributeName': 'company', 'AttributeType': 'S'},
                {'AttributeName': 'jobTitle', 'AttributeType': 'S'},
                {'AttributeName': 'city_state', 'AttributeType': 'S'},
                {'AttributeName': 'type', 'AttributeType': 'S'},
                {'AttributeName': 'email', 'AttributeType': 'S'},
                {'AttributeName': 'slug', 'AttributeType': 'S'},
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'SKIndex',
                    'KeySchema': [
                        {'AttributeName': 'SK', 'KeyType': 'HASH'},
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'CompanyIndex',
                    'KeySchema': [
                        {'AttributeName': 'company', 'KeyType': 'HASH'},
                        {'AttributeName': 'PK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'JobTitleIndex',
                    'KeySchema': [
                        {'AttributeName': 'jobTitle', 'KeyType': 'HASH'},
                        {'AttributeName': 'PK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'CityStateIndex',
                    'KeySchema': [
                        {'AttributeName': 'city_state', 'KeyType': 'HASH'},
                        {'AttributeName': 'PK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'TypeIndex',
                    'KeySchema': [
                        {'AttributeName': 'type', 'KeyType': 'HASH'},
                        {'AttributeName': 'PK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'EmailIndex',
                    'KeySchema': [{'AttributeName': 'email', 'KeyType': 'HASH'}],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'SlugIndex',
                    'KeySchema': [
                        {'AttributeName': 'slug', 'KeyType': 'HASH'},
                    ],
                    'Projection': {'ProjectionType': 'ALL'},
                },
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        print("CRM main table created with GSIs.")
    except Exception as e:
        print(f"{MAIN_TABLE_NAME} creation skipped or failed: {e}")

    try:
        dynamodb.create_table(
            TableName=EMAIL_TABLE_NAME,
            KeySchema=[
                {'AttributeName': 'PK', 'KeyType': 'HASH'},
                {'AttributeName': 'SK', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'PK', 'AttributeType': 'S'},
                {'AttributeName': 'SK', 'AttributeType': 'S'},
                {'AttributeName': 'type', 'AttributeType': 'S'}
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'EmailIndex',
                    'KeySchema': [
                        {'AttributeName': 'PK', 'KeyType': 'HASH'},
                        {'AttributeName': 'SK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'UserIndex',
                    'KeySchema': [
                        {'AttributeName': 'SK', 'KeyType': 'HASH'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'TypeIndex',
                    'KeySchema': [
                        {'AttributeName': 'type', 'KeyType': 'HASH'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                }
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        print(f"CRM {EMAIL_TABLE_NAME} table created with GSIs.")
    except Exception as e:
        print(f"{EMAIL_TABLE_NAME} creation skipped or failed: {e}")

def delete_table(table_name):
    import boto3
    from botocore.config import Config

    # Get configuration from environment variables
    region = os.getenv('AWS_REGION', 'us-west-2')
    endpoint_url = os.getenv('DYNAMODB_ENDPOINT', 'http://localhost:8000')
    access_key = os.getenv('AWS_ACCESS_KEY_ID', 'dummy')
    secret_key = os.getenv('AWS_SECRET_ACCESS_KEY', 'dummy')
    
    # Create client with timeout settings
    dynamodb = boto3.client("dynamodb", 
        region_name=region,
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        config=Config(
            retries={'max_attempts': 3, 'mode': 'standard'},
            connect_timeout=CONNECTION_TIMEOUT,
            read_timeout=CONNECTION_TIMEOUT
        ), 
        endpoint_url=endpoint_url)  # adjust if using AWS
    
    try:
        dynamodb.delete_table(TableName=table_name)
        print(f"Deleting table: {table_name}...")
        waiter = dynamodb.get_waiter('table_not_exists')
        waiter.wait(TableName=table_name)
        print(f" {table_name} deleted.")
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            print("Table doesn't exist. Skipping deletion.")
        else:
            raise

def reset_all_table():
    try:
        print("Attempting to reset tables...")
        delete_table(MAIN_TABLE_NAME)
        delete_table(EMAIL_TABLE_NAME)
        create_tables()
        print("Tables reset successfully.")
    except Exception as e:
        print(f"Error resetting tables: {e}")
        print("If DynamoDB is not available, please ensure it's running before continuing.")
        # Don't raise the exception - allow the application to continue even if tables can't be reset

if __name__ == "__main__":
    reset_all_table()