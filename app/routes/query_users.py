from fastapi import APIRouter, Query, HTTPException
from app.models import UserFilter, User
from app.services.db.session import table
from boto3.dynamodb.conditions import Key
from typing import List, Optional, Annotated
from decimal import Decimal
from pydantic import StringConstraints, BaseModel
from app.services.opensearch.client import get_opensearch_client
# from fastapi.responses import ORJSONResponse

router = APIRouter()
'''
@router.post("/basic-filter-users", response_model=List[User])
def filter_users(
    filter: UserFilter,
    sort_by: Annotated[str | None, StringConstraints(pattern="^(attendedCount|hostedCount)$")] = None,
    limit: int = 50,
    lastKey: Optional[str] = None,
    sort_order: Optional[str] = Query("desc", pattern="^(asc|desc)$")
):
    # Step 1: Collect queries for all provided filters
    queries = []
    if filter.company:
        queries.append({
            "IndexName": "CompanyIndex",
            "KeyConditionExpression": Key("company").eq(filter.company),
            "Limit": limit
        })
    if filter.jobTitle:
        queries.append({
            "IndexName": "JobTitleIndex",
            "KeyConditionExpression": Key("jobTitle").eq(filter.jobTitle),
            "Limit": limit
        })
    if filter.city and filter.state:
        city_state = f"{filter.city}#{filter.state}"
        queries.append({
            "IndexName": "CityStateIndex",
            "KeyConditionExpression": Key("city_state").eq(city_state),
            "Limit": limit
        })

    if not queries:
        raise ValueError("At least one filter among company, jobTitle, or city+state must be provided")

    # Step 2: Query all indexes and collect PKs
    pk_sets = []
    for q in queries:
        if lastKey:
            q["ExclusiveStartKey"] = {"PK": lastKey, "SK": lastKey}
        result = table.query(**q)
        items = result.get("Items", [])
        pks = set(item["PK"] for item in items)
        pk_sets.append(pks)

    # Step 3: Intersect PKs to get users matching all filters
    if pk_sets:
        matching_pks = set.intersection(*pk_sets)
    else:
        matching_pks = set()

    # Step 4: Collect all items from the first query and filter by PK
    # (Assume all items have the same structure)
    users_raw = []
    if queries:
        first_query = queries[0]
        if lastKey:
            first_query["ExclusiveStartKey"] = {"PK": lastKey, "SK": lastKey}
        result = table.query(**first_query)
        users_raw = [item for item in result.get("Items", []) if item["PK"] in matching_pks]

    # Step 5: In-memory filtering
    users = []
    for item in users_raw:
        attended = int(item.get("attendedCount", 0))
        hosted = int(item.get("hostedCount", 0))

        if filter.minAttended is not None and attended < filter.minAttended:
            continue
        if filter.maxAttended is not None and attended > filter.maxAttended:
            continue
        if filter.minHosted is not None and hosted < filter.minHosted:
            continue
        if filter.maxHosted is not None and hosted > filter.maxHosted:
            continue

        users.append(User(
            id=item["PK"].split("#")[1],
            firstName=item["firstName"],
            lastName=item["lastName"],
            email=item["email"],
            phoneNumber=item.get("phoneNumber"),
            avatar=item.get("avatar"),
            gender=item.get("gender"),
            jobTitle=item.get("jobTitle"),
            company=item.get("company"),
            city=item.get("city"),
            state=item.get("state"),
            attendedCount=attended,
            hostedCount=hosted
        ))

    # Step 6: Sorting
    if sort_by:
        users.sort(key=lambda u: getattr(u, sort_by), reverse=sort_order == "desc")

    return users

'''

class UserSearchResponse(BaseModel):
    total: int
    users: list[User]

@router.post("/query_users", response_model=UserSearchResponse,  response_model_exclude_none=True)
def filter_users_opensearch(filter: UserFilter, page: int = 0, size: int = 10):

    os_client = get_opensearch_client()

    must_clauses = []

    if filter.company:
        must_clauses.append({"match": {"company": filter.company}})
    if filter.jobTitle:
        must_clauses.append({"match": {"jobTitle": filter.jobTitle}})
    if filter.city:
        must_clauses.append({"match": {"city": filter.city}})
    if filter.state:
        must_clauses.append({"match": {"state": filter.state}})

    if filter.minAttended is not None or filter.maxAttended is not None:
        attended_range = {}
        if filter.minAttended is not None:
            attended_range["gte"] = filter.minAttended
        if filter.maxAttended is not None:
            attended_range["lte"] = filter.maxAttended
        must_clauses.append({"range": {"attendedCount": attended_range}})

    if filter.minHosted is not None or filter.maxHosted is not None:
        hosted_range = {}
        if filter.minHosted is not None:
            hosted_range["gte"] = filter.minHosted
        if filter.maxHosted is not None:
            hosted_range["lte"] = filter.maxHosted
        must_clauses.append({"range": {"hostedCount": hosted_range}})

    try:
        response = os_client.search(
            index="users",
            body={
                "query": {
                    "bool": {
                        "must": must_clauses
                    }
                },
                "from": page * size,
                "size": size
            }
        )

        total = response["hits"]["total"]["value"] if isinstance(response["hits"]["total"], dict) else response["hits"]["total"]
        users = [User(**hit["_source"]) for hit in response["hits"]["hits"]]
        return UserSearchResponse(total=total, users=users)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
