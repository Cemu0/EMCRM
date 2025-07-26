from fastapi import APIRouter, HTTPException
from app.models import Event, EventAttendance
from app.services.db.session import table
from boto3.dynamodb.conditions import Key
from datetime import datetime
from app.services.opensearch.client import get_opensearch_client
from fastapi.concurrency import run_in_threadpool
from fastapi_pagination import Page, add_pagination, paginate

router = APIRouter()

def increment_hosted_count(user_id: str):
    if not user_id or user_id.strip() == "":
        print(f"Warning: Skipping hosted count increment for empty user_id")
        return
        
    key = {"PK": f"user#{user_id}", "SK": f"user#{user_id}"}
    res = table.update_item(
        Key=key,
        UpdateExpression="SET hostedCount = if_not_exists(hostedCount, :zero) + :incr",
        ExpressionAttributeValues={": incr": 1, ":zero": 0},
        ReturnValues="UPDATED_NEW"
    )
    new_count = res["Attributes"]["hostedCount"]
    os_client = get_opensearch_client()
    
    # Additional validation before OpenSearch update
    if os_client and user_id:
        os_client.update(
            index="users",
            id=user_id,
            body={"doc": {"hostedCount": new_count}}
        )

def decrement_hosted_count(user_id: str):
    if not user_id or user_id.strip() == "":
        print(f"Warning: Skipping hosted count decrement for empty user_id")
        return
        
    key = {"PK": f"user#{user_id}", "SK": f"user#{user_id}"}
    res = table.update_item(
        Key=key,
        UpdateExpression="SET hostedCount = if_not_exists(hostedCount, :zero) - :decr",
        ExpressionAttributeValues={": decr": 1, ":zero": 0},
        ReturnValues="UPDATED_NEW"
    )
    new_count = res["Attributes"]["hostedCount"]
    os_client = get_opensearch_client()
    
    # Additional validation before OpenSearch update
    if os_client and user_id:
        os_client.update(
            index="users",
            id=user_id,
            body={"doc": {"hostedCount": new_count}}
        )

@router.post("/", response_model=Event)
def create_event(event: Event):
    
    result = table.query(
        IndexName="SlugIndex",
        KeyConditionExpression=Key("slug").eq(event.slug)
    )
    if result["Count"] > 0:
        raise HTTPException(status_code=400, detail="Event slug already exists")
    
    item = event.to_dynamodb_item()
    table.put_item(Item=item)

    # Update hostedCount for owner and hosts
    owner_id = event.owner
    increment_hosted_count(owner_id)

    for host_id in event.hosts:
        increment_hosted_count(host_id)

    return event

@router.get("/{event_id}", response_model=Event)
async def get_event(event_id: str):
    pk = f"event#{event_id}"
    res = await run_in_threadpool(table.get_item, Key={"PK": pk, "SK": pk})
    item = res.get("Item")
    if not item:
        raise HTTPException(status_code=404, detail="Event not found")
    return Event(**item)

@router.put("/{event_id}", response_model=Event)
def update_event(event_id: str, event_update: Event):
    pk = f"event#{event_id}"
    
    res = table.get_item(Key={"PK": pk, "SK": pk})
    if "Item" not in res:
        raise HTTPException(status_code=404, detail="Event not found")

    # Optional: check for slug conflict if slug is changing
    existing_slug = res["Item"].get("slug")
    if event_update.slug != existing_slug:
        slug_check = table.query(
            IndexName="SlugIndex",
            KeyConditionExpression=Key("slug").eq(event_update.slug)
        )
        if slug_check["Count"] > 0:
            raise HTTPException(status_code=400, detail="Slug already exists")

    item = event_update.to_dynamodb_item()
    table.put_item(Item=item)

    return event_update


@router.delete("/{event_id}")
def delete_event(event_id: str):
    pk = f"event#{event_id}"
    res = table.get_item(Key={"PK": pk, "SK": pk})
    if "Item" not in res:
        raise HTTPException(status_code=404, detail="Event not found")

    event = res["Item"]

    table.delete_item(Key={"PK": pk, "SK": pk})

    # Optional: decrement hostedCount for owner/hosts
    decrement_hosted_count(event["owner"])
    for host_id in event.get("hosts", []):
        decrement_hosted_count(host_id)

    return {"message": "Event deleted successfully"}

@router.get("/", response_model=Page[Event])
async def get_events():
    """Get all events with pagination"""
    res = await run_in_threadpool(
        table.query,
        IndexName="TypeIndex",
        KeyConditionExpression=Key("type").eq("event")
    )
    
    items = res.get("Items", [])
    
    events = [
        Event(
            id=item["PK"].split("#", 1)[1],
            slug=item["slug"],
            title=item["title"],
            description=item.get("description"),
            startAt=item["startAt"],
            endAt=item["endAt"],
            venue=item.get("venue"),
            maxCapacity=item.get("maxCapacity"),
            owner=item["owner"],
            hosts=item.get("hosts", [])
        )
        for item in items
    ]
    
    return paginate(events)


