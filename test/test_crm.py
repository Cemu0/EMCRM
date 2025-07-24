import pytest
from fastapi.testclient import TestClient
from uuid import uuid4
from datetime import datetime, timedelta
from app.services.opensearch.client import get_opensearch_client
from app.main import app
from app.services.db.init import reset_all_table
from fastapi_pagination import Page, add_pagination, paginate
from fastapi_pagination.utils import disable_installed_extensions_check
from app.config import settings

if settings.auth.enabled:
    Exception("Auth is enabled! Please disable it for testing.")

disable_installed_extensions_check()

add_pagination(app)

client = TestClient(app)

@pytest.fixture(autouse=True)
def setup_and_teardown():
    reset_all_table()
    os_client = get_opensearch_client()
    try:
        os_client.indices.delete(index="users")
    except:
        pass
    yield

def unique_email():
    return f"{uuid4().hex[:8]}@test.com"


def test_health_check():
    res = client.get("/health/")    
    assert res.status_code == 200
    print(res.json())
    assert res.json() == {
        "dynamodb": "ok",
        "opensearch": "ok"
    }

def test_create_user_success():
    res = client.post("/users/", json={
        "firstName": "Alice",
        "lastName": "Smith",
        "email": unique_email(),
        "company": "Acme Corp",
        "jobTitle": "Engineer",
        "city": "NYC",
        "state": "NY"
    })    
    
    assert res.status_code == 200
    data = res.json()
    assert "id" in data
    assert data["firstName"] == "Alice"

def test_update_user_success():
    # Create user first
    create_res = client.post("/users/", json={
        "firstName": "Initial",
        "lastName": "User",
        "email": unique_email(),
        "company": "Old Company",
        "jobTitle": "Developer"
    })
    assert create_res.status_code == 200
    user_id = create_res.json()["id"]

    # Update user
    update_res = client.put(f"/users/{user_id}", json={
        "id": user_id,
        "firstName": "Updated",
        "lastName": "User",
        "email": unique_email(),  # use new email
        "company": "New Company",
        "jobTitle": "Lead Dev"
    })
    assert update_res.status_code == 200
    data = update_res.json()
    assert data["firstName"] == "Updated"
    assert data["company"] == "New Company"

    # Confirm update via GET
    get_res = client.get(f"/users/{user_id}")
    assert get_res.status_code == 200
    assert get_res.json()["company"] == "New Company"

def test_update_nonexistent_user_should_fail():
    res = client.put("/users/nonexistent-id", json={
        "id": "nonexistent-id",
        "firstName": "Ghost",
        "lastName": "User",
        "email": unique_email()
    })
    assert res.status_code == 404

def test_delete_user_success():
    # Create user
    res = client.post("/users/", json={
        "firstName": "DeleteMe",
        "lastName": "Test",
        "email": unique_email()
    })
    assert res.status_code == 200
    user_id = res.json()["id"]

    # Delete
    delete_res = client.delete(f"/users/{user_id}")
    assert delete_res.status_code == 200
    assert delete_res.json()["message"] == "User deleted successfully"

    # Confirm deletion
    get_res = client.get(f"/users/{user_id}")
    assert get_res.status_code == 404

def test_delete_nonexistent_user_should_fail():
    res = client.delete("/users/ghost-id")
    assert res.status_code == 404


def test_duplicate_email_should_fail():
    res = client.post("/users/", json={
        "firstName": "Bob",
        "lastName": "Brown",
        "email": "test@email.com"
    })
    assert res.status_code == 200
    user_id = res.json()["id"]

    email = unique_email()
    client.put(f"/users/{user_id}", json={
        "firstName": "Bob",
        "lastName": "Brown",
        "email": email
    })
    # import time
    # time.sleep(1)
    res = client.post("/users/", json={
        "firstName": "Charlie",
        "lastName": "Clark",
        "email": email
    })
    assert res.status_code in [400, 409]

def test_get_user_success():
    res = client.post("/users/", json={
        "firstName": "Diana",
        "lastName": "Prince",
        "email": unique_email()
    })
    user_id = res.json()["id"]
    get_res = client.get(f"/users/{user_id}")
    assert get_res.status_code == 200
    assert get_res.json()["id"] == user_id

def test_create_event_success():
    owner_res = client.post("/users/", json={
        "firstName": "Eve",
        "lastName": "Adams",
        "email": unique_email()
    })
    owner_id = owner_res.json()["id"]

    res = client.post("/events/", json={
        "slug": f"event-{uuid4().hex[:6]}",
        "title": "Tech Meetup",
        "startAt": datetime.now().isoformat(),
        "endAt": (datetime.now() + timedelta(hours=2)).isoformat(),
        "owner": owner_id,
        "hosts": [owner_id],
        "venue": "Main Hall"
    })
    assert res.status_code == 200
    event_data = res.json()
    assert "id" in event_data
    assert event_data["title"] == "Tech Meetup"

def test_duplicate_slug_should_fail():
    owner_res = client.post("/users/", json={
        "firstName": "Frank",
        "lastName": "Gates",
        "email": unique_email()
    })
    owner_id = owner_res.json()["id"]

    slug = f"dupe-event-{uuid4().hex[:4]}"
    payload = {
        "slug": slug,
        "title": "Same Slug Event",
        "startAt": datetime.now().isoformat(),
        "endAt": (datetime.now() + timedelta(hours=1)).isoformat(),
        "owner": owner_id
    }
    client.post("/events/", json=payload)
    res = client.post("/events/", json=payload)
    assert res.status_code in [400, 409]

def test_update_event_success():
    # Create a user to own the event
    owner_res = client.post("/users/", json={
        "firstName": "Update",
        "lastName": "Tester",
        "email": unique_email()
    })
    owner_id = owner_res.json()["id"]

    # Create the event
    create_res = client.post("/events/", json={
        "slug": f"updatable-{uuid4().hex[:6]}",
        "title": "Initial Title",
        "startAt": datetime.now().isoformat(),
        "endAt": (datetime.now() + timedelta(hours=1)).isoformat(),
        "owner": owner_id
    })
    assert create_res.status_code == 200
    event_id = create_res.json()["id"]

    # Update the event
    update_res = client.put(f"/events/{event_id}", json={
        "id": event_id,
        "slug": f"updated-{uuid4().hex[:6]}",
        "title": "Updated Title",
        "startAt": datetime.now().isoformat(),
        "endAt": (datetime.now() + timedelta(hours=2)).isoformat(),
        "owner": owner_id,
        "hosts": [owner_id],
        "venue": "Updated Venue"
    })
    assert update_res.status_code == 200
    assert update_res.json()["title"] == "Updated Title"
    assert update_res.json()["venue"] == "Updated Venue"

def test_update_event_with_existing_slug_should_fail():
    owner_res = client.post("/users/", json={
        "firstName": "Slug",
        "lastName": "Conflict",
        "email": unique_email()
    })
    owner_id = owner_res.json()["id"]

    slug = f"conflict-{uuid4().hex[:4]}"

    # First event with the slug
    first = client.post("/events/", json={
        "slug": slug,
        "title": "First Event",
        "startAt": datetime.now().isoformat(),
        "endAt": (datetime.now() + timedelta(hours=1)).isoformat(),
        "owner": owner_id
    })

    # Second event
    second = client.post("/events/", json={
        "slug": f"unique-{uuid4().hex[:4]}",
        "title": "Second Event",
        "startAt": datetime.now().isoformat(),
        "endAt": (datetime.now() + timedelta(hours=1)).isoformat(),
        "owner": owner_id
    })
    second_id = second.json()["id"]

    # Try to update second event with duplicate slug
    res = client.put(f"/events/{second_id}", json={
        "id": second_id,
        "slug": slug,
        "title": "Updated Event",
        "startAt": datetime.now().isoformat(),
        "endAt": (datetime.now() + timedelta(hours=2)).isoformat(),
        "owner": owner_id
    })
    assert res.status_code == 400

def test_update_nonexistent_event_should_fail():
    res = client.put("/events/nonexistent-event-id", json={
        "id": "nonexistent-event-id",
        "slug": "nonexistent-slug",
        "title": "Ghost Event",
        "startAt": datetime.now().isoformat(),
        "endAt": (datetime.now() + timedelta(hours=1)).isoformat(),
        "owner": "fake-user-id"
    })
    assert res.status_code == 404

def test_delete_event_success():
    owner_res = client.post("/users/", json={
        "firstName": "Delete",
        "lastName": "Event",
        "email": unique_email()
    })
    owner_id = owner_res.json()["id"]

    create_res = client.post("/events/", json={
        "slug": f"delete-{uuid4().hex[:5]}",
        "title": "To Be Deleted",
        "startAt": datetime.now().isoformat(),
        "endAt": (datetime.now() + timedelta(hours=1)).isoformat(),
        "owner": owner_id
    })
    event_id = create_res.json()["id"]

    # Delete event
    delete_res = client.delete(f"/events/{event_id}")
    assert delete_res.status_code == 200
    assert delete_res.json()["message"] == "Event deleted successfully"

    # Try to get deleted event
    get_res = client.get(f"/events/{event_id}")
    assert get_res.status_code == 404

def test_delete_nonexistent_event_should_fail():
    res = client.delete("/events/nonexistent-id")
    assert res.status_code == 404



def test_attend_event():
    user_res = client.post("/users/", json={
        "firstName": "Gina",
        "lastName": "Walker",
        "email": unique_email()
    })
    user_id = user_res.json()["id"]
    time_check = datetime.now().isoformat()
    event_res = client.post("/events/", json={
        "slug": f"attend-{uuid4().hex[:6]}",
        "title": "Networking",
        "startAt": time_check,
        "endAt": (datetime.now() + timedelta(hours=1)).isoformat(),
        "owner": user_id
    })
    event_id = event_res.json()["id"]

    attend_res = client.post("/attend/", json={
        "user_id": user_id,
        "event_id": event_id
    })
    assert attend_res.status_code == 200
    assert attend_res.json()["user_id"] == user_id

    # Duplicate should be rejected 
    repeat_res = client.post("/attend/", json={
        "user_id": user_id,
        "event_id": event_id
    })
    assert repeat_res.status_code == 400

    # query event
    event_res = client.get(f"/events/{event_id}")

    assert event_res.json()["startAt"] == time_check

    # query attend
    event_res = client.get(f"/attend/user/{user_id}")
    print(event_res.json())
    assert event_res.json()["items"][0]["event_id"] == event_id

    event_res = client.get(f"/attend/event/{event_id}")
    assert event_res.json()["items"][0]["event_id"] == event_id

# def test_simple_filter_users_endpoint():
#     res = client.post("/search/basic-filter-users", json={
#         "company": "NonExistent",
#         "minHosted": 10
#     })
#     assert res.status_code == 200
#     assert isinstance(res.json(), list)

def test_filter_users_opensearch_endpoint():
    client.post("/users/", json={
        "firstName": "Gina",
        "lastName": "Walker",
        "email": unique_email()
    })
    res = client.post("/search/query_users", json={
        "company": "NonExistent",
        "minHosted": 10
    })
    assert res.status_code == 200
    assert isinstance(res.json(), dict)

def test_email_filter_post():
    user_res = client.post("/users/", json={
        "firstName": "Henry",
        "lastName": "Jones",
        "email": unique_email(),
        "company": "Example Inc",
        "jobTitle": "CTO",
        "city": "LA",
        "state": "CA"
    })
    import time 
    time.sleep(1) #wait for data sync!~
    # print(user_res.json())
    res = client.post("/email/send_emails/", json={
        "filter": {
            "company": "Example Inc",
            "minAttended": 0
        },
        "subject": "Event Reminder",
        "body": "Join our next event!"
    })
    print(res.json())
    assert res.status_code == 200
    assert res.json()["totalRecipients"] == 1


