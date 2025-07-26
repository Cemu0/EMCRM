from fastapi import APIRouter, HTTPException
from fastapi_pagination import Page, add_pagination, paginate
from uuid import uuid4
from datetime import datetime
from app.models import User
from app.models import EmailRequest, Email, EmailStatusEnum
from app.routes.query_users import filter_users_opensearch, UserSearchResponse
from app.services.email_sender import send_bulk_emails
from app.services.db.session import email_table 
from boto3.dynamodb.conditions import Key
from typing import List, Annotated
# from fastapi.responses import ORJSONResponse
router = APIRouter()


@router.get("/", response_model=Page[EmailRequest], response_model_exclude_none=True)
async def get_email_requests():
    response = email_table.query(
        IndexName="TypeIndex",
        KeyConditionExpression=Key("type").eq("email_request")
    )
    
    if "Items" not in response or len(response["Items"]) == 0:
        raise HTTPException(status_code=404, detail="Item not found")


    return paginate(response["Items"])

@router.post("/send_emails", response_model=EmailRequest, response_model_exclude_none=True)
async def send_email_to_filtered_users(request: EmailRequest):
    # 1. Filter users using OpenSearch
    search_result: UserSearchResponse = filter_users_opensearch(request.filter, size=10000)

    if search_result.total == 0:
        raise HTTPException(status_code=404, detail="No users match the given filter.")
    
    users = search_result.users

    # 2. Generate unique email_id
    email_id = str(uuid4())

    # 3. Extract emails and send
    email_list = [user.email for user in users if user.email]
    
    # dummy sent
    send_bulk_emails(email_list, subject=request.subject, body=request.body)

    # 4. Prepare EmailRequest record
    request.email_id = email_id
    request.createdAt = datetime.now()
    request.totalRecipients = len(email_list)
    request.status = EmailStatusEnum.sent

    request_item = request.to_dynamodb_item()
    email_table.put_item(Item=request_item)

    # 5. Log delivery status for each user
    for user in users:
        log = Email(
            user_id=user.id,
            email_id=email_id,
            status=EmailStatusEnum.sent,
            createdAt=datetime.now()
        )
        email_table.put_item(Item=log.to_dynamodb_item())
    
    return request

@router.post("/{email_id}", response_model=EmailRequest, response_model_exclude_none=True)
async def get_email_sent_request(email_id: str):
    pk = f"email#{email_id}"
    response = email_table.get_item(Key={"PK": pk, "SK": pk})
    item = response.get("Item")
    print(response)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item

@router.post("/sent/{email_id}", response_model=Page[Email], response_model_exclude_none=True)
async def get_emails_status(email_id: str):
    response = email_table.query(
        IndexName="EmailIndex",
        KeyConditionExpression=Key("PK").eq(f"req_email#{email_id}")
    )
    
    if "Items" not in response or len(response["Items"]) == 0:
        raise HTTPException(status_code=404, detail="Item not found")

    emails = []
    for item in response["Items"]:
        emails.append({
            "createdAt": item["createdAt"],
            "user_id": item["SK"].split("#")[1],
            "email_id": item["PK"].split("#")[1],
            "status": EmailStatusEnum(item["status"]),
        })
    return paginate(emails)

@router.post("/user/{user_id}", response_model=Page[Email], response_model_exclude_none=True)
async def get_emails_status(user_id: str):
    response = email_table.query(
        IndexName="UserIndex",
        KeyConditionExpression=Key("SK").eq(f"user#{user_id}")
    )
    
    if "Items" not in response or len(response["Items"]) == 0:
        raise HTTPException(status_code=404, detail="Item not found")

    emails = []
    for item in response["Items"]:
        emails.append({
            "createdAt": item["createdAt"],
            "user_id": item["SK"].split("#")[1],
            "email_id": item["PK"].split("#")[1],
            "status": EmailStatusEnum(item["status"]),
        })
    return paginate(emails)

