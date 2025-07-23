from fastapi import APIRouter, HTTPException, Body
from app.models import User
from app.db.session import table  # reference to boto3 DynamoDB Table
from boto3.dynamodb.conditions import Key
from app.opensearch.client import get_opensearch_client
from fastapi.concurrency import run_in_threadpool
from fastapi import BackgroundTasks

router = APIRouter()

@router.post("/", response_model=User)
async def create_user(user: User, background_tasks: BackgroundTasks):
    
    pk = f"user#{user.id}"
    
    existing = await run_in_threadpool(table.get_item, Key={"PK": pk, "SK": pk})
    if "Item" in existing:
        raise HTTPException(status_code=400, detail="User ID already exists")
    
    result = await run_in_threadpool(table.query,
        IndexName="EmailIndex",
        KeyConditionExpression=Key("email").eq(str(user.email))
    )
    if result.get("Count", 0) > 0:
        raise HTTPException(status_code=400, detail="Email already exists")

    item = user.to_dynamodb_item()

    await run_in_threadpool(table.put_item,Item=item)

    os_client = get_opensearch_client()

    if os_client:
        background_tasks.add_task(os_client.index,
            index="users",
            id=user.id,
            body=user.to_opensearch_doc())

    return user

@router.get("/{user_id}", response_model=User)
async def get_user(user_id: str):
    pk = f"user#{user_id}"
    res = await run_in_threadpool(table.get_item,Key={"PK": pk, "SK": pk})
    item = res.get("Item")
    if not item:
        raise HTTPException(status_code=404, detail="User not found")
    return User(**{
        "id": user_id,
        "firstName": item["firstName"],
        "lastName": item["lastName"],
        "email": item["email"],
        "phoneNumber": item.get("phoneNumber"),
        "avatar": item.get("avatar"),
        "gender": item.get("gender"),
        "jobTitle": item.get("jobTitle"),
        "company": item.get("company"),
        "city": item.get("city"),
        "state": item.get("state"),
        "attendedCount": item.get("attendedCount", 0),
        "hostedCount": item.get("hostedCount", 0),
    })

@router.put("/{user_id}", response_model=User)
async def update_user(user_id: str, user_update: User = Body(...)):
    pk = f"user#{user_id}"
    
    existing = await run_in_threadpool(table.get_item,Key={"PK": pk, "SK": pk})
    if not existing.get("Item"):
        raise HTTPException(status_code=404, detail="User not found")
    
    if user_update.email != existing["Item"].get("email"):
        result = await run_in_threadpool(table.query,
            IndexName="EmailIndex",
            KeyConditionExpression=Key("email").eq(str(user_update.email))
        )
        if result.get("Count", 0) > 0:
            raise HTTPException(status_code=400, detail="Email already exists")
    

    updated_item = user_update.to_dynamodb_item()
    updated_item["PK"] = pk
    updated_item["SK"] = pk

    # Update city_state if city and state exist
    if user_update.city and user_update.state:
        updated_item["city_state"] = f"{user_update.city}#{user_update.state}"

    await run_in_threadpool(table.put_item,Item=updated_item)

    os_client = get_opensearch_client()
    if os_client:
        await run_in_threadpool(os_client.index,
            index="users",
            id=user_id,
            body=user_update.to_opensearch_doc()
        )

    return user_update

@router.delete("/{user_id}")
def delete_user(user_id: str):
    pk = f"user#{user_id}"
    
    # Check if exists
    existing = table.get_item(Key={"PK": pk, "SK": pk}).get("Item")
    if not existing:
        raise HTTPException(status_code=404, detail="User not found")

    # Delete from DynamoDB
    table.delete_item(Key={"PK": pk, "SK": pk})

    # Delete from OpenSearch
    os_client = get_opensearch_client()
    if os_client:
        try:
            os_client.delete(index="users", id=user_id)
        except Exception:
            pass  # Swallow OS errors silently

    return {"message": "User deleted successfully"}