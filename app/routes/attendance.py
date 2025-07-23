from fastapi import APIRouter, HTTPException
from boto3.dynamodb.conditions import Key
from ..models import EventAttendance
from ..db.session import table
from app.opensearch.client import get_opensearch_client
from fastapi_pagination import Page, add_pagination, paginate
from fastapi.concurrency import run_in_threadpool

router = APIRouter()

def increment_attended_count(user_id: str):
    key = {"PK": f"user#{user_id}", "SK": f"user#{user_id}"}
    res = table.update_item(
        Key=key,
        UpdateExpression="SET attendedCount = if_not_exists(attendedCount, :zero) + :incr",
        ExpressionAttributeValues={":incr": 1, ":zero": 0},
        ReturnValues="UPDATED_NEW"
    )   
    new_count = res["Attributes"]["attendedCount"]
    os_client = get_opensearch_client()
    os_client.update(
        index="users",
        id=user_id,
        body={"doc": {"attendedCount": new_count}}
    )   
        

@router.post("/", response_model=EventAttendance)
async def create_attendance(attendance: EventAttendance):
    pk = f"user#{attendance.user_id}"
    sk = f"event#{attendance.event_id}"

    # Check if already attended
    existing = table.get_item(Key={"PK": pk, "SK": sk})
    if "Item" in existing:
        raise HTTPException(status_code=400, detail="Attendance record already exists")
    
    # check user exists
    user_check = table.get_item(Key={"PK": pk, "SK": pk})
    if "Item" not in user_check:
        raise HTTPException(status_code=404, detail="User not found")
    
    # check event exists
    event_check = table.get_item(Key={"PK": f"event#{attendance.event_id}",
                                        "SK": f"event#{attendance.event_id}"})
    if "Item" not in event_check:
        raise HTTPException(status_code=404, detail="Event not found")

    item = attendance.to_dynamodb_item()

    await run_in_threadpool(table.put_item, Item=item)
    await run_in_threadpool(increment_attended_count, attendance.user_id)
    return attendance



@router.get("/user/{user_id}", response_model=Page[EventAttendance])
async def get_user_attendance(user_id: str):
    pk = f"user#{user_id}"
    res = await run_in_threadpool(table.query,
        KeyConditionExpression=Key("PK").eq(pk) & Key("SK").begins_with("event#"),
        FilterExpression="#t = :type",
        ExpressionAttributeNames={"#t": "type"},
        ExpressionAttributeValues={":type": "attendance"}
    )

    return paginate([
        EventAttendance(
            user_id=user_id,
            event_id=item["SK"].split("#", 1)[1],
            attended=item.get("attended", False),
            createdAt=item["createdAt"],
        )
        for item in res.get("Items", [])
    ])

@router.get("/event/{event_id}", response_model=Page[EventAttendance])
async def get_event_attendance(event_id: str):

    res = await run_in_threadpool(table.query,
            IndexName='SKIndex',
            KeyConditionExpression=Key("SK").eq(f"event#{event_id}"),
            FilterExpression="#t = :type",
            ExpressionAttributeNames={"#t": "type"},
            ExpressionAttributeValues={":type": "attendance"}
        )
    items = res.get("Items", [])

    return paginate([
        EventAttendance(
            user_id=item["PK"].split("#", 1)[1],
            event_id=event_id,
            attended=item["attended"],
            createdAt=item["createdAt"],
        )
        for item in items
    ])

