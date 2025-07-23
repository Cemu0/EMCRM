from fastapi import APIRouter
from fastapi.responses import JSONResponse
from boto3.dynamodb.conditions import Key
from botocore.exceptions import BotoCoreError, ClientError
from opensearchpy.exceptions import OpenSearchException

from ..db.session import table
from ..opensearch.client import get_opensearch_client

router = APIRouter()

@router.get("/health", summary="Check system health")
async def health_check():
    status = {"dynamodb": "ok", "opensearch": "ok"}

    # Check DynamoDB
    try:
        # Perform a lightweight dummy request
        table.table_status  # Forces a call to describe_table
    except (BotoCoreError, ClientError) as e:
        status["dynamodb"] = f"error: {str(e)}"

    # Check OpenSearch
    try:
        client = get_opensearch_client()
        if client:
            client.info()
        else:
            status["opensearch"] = "disabled"
    except OpenSearchException as e:
        status["opensearch"] = f"error: {str(e)}"

    http_status = 200 if all(v == "ok" or v == "disabled" for v in status.values()) else 503
    return JSONResponse(content=status, status_code=http_status)
