import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.services.db.init import reset_all_table
from app.services.opensearch.client import get_opensearch_client
from app.models import GenderEnum
from uuid import uuid4
import random
from time import sleep
from tqdm import tqdm 

client = TestClient(app)

@pytest.fixture(autouse=True)
def setup_and_teardown():
    # reset_all_table()
    # os_client = get_opensearch_client()
    # try:
    #     os_client.indices.delete(index="users")
    # except:
    #     pass
    yield

# Define fixed lists
COMPANIES = [
    "TechCorp", "Innovate Solutions", "Data Dynamics", "CloudNet", "BrightFuture Inc",
    "Global Systems", "NexGen Tech", "Synergy Labs", "Quantum Ventures", "Alpha Analytics"
]
CITIES = [
    "New York", "San Francisco", "Chicago", "Austin", "Seattle",
    "Boston", "Los Angeles", "Denver", "Miami", "Portland"
]
STATES = [
    "NY", "CA", "IL", "TX", "WA",
    "MA", "CA", "CO", "FL", "OR"
]

def generate_random_phone():
    return f"+1{random.randint(200, 999)}{random.randint(100, 999)}{random.randint(1000, 9999)}"

# Helper function to generate random user data
def generate_random_user(i: int) -> dict:
    return {
        "firstName": f"User{i}",
        "lastName": random.choice(["Smith", "Johnson", "Lee", "Brown", "Davis", "Wilson"]),
        "email": f"user{i}@loadtest{random.randint(1, 100)}.com",
        "phoneNumber": generate_random_phone() if random.random() > 0.5 else None,
        "avatar": f"https://avatar.example.com/{i}.png" if random.random() > 0.7 else None,
        "gender": random.choice([GenderEnum.male, GenderEnum.female, GenderEnum.other, None]),
        "jobTitle": random.choice(["Engineer", "Manager", "Analyst", "Designer", "Developer", None]),
        "company": random.choice(COMPANIES + [None]),  # Include None for optional
        "city": random.choice(CITIES + [None]),        # Include None for optional
        "state": random.choice(STATES + [None])        # Include None for optional
    }

def create_event(i: int, user_id) -> dict:

    event_data = {
        "title": f"Event {i}",
        "slug": f"attend-{uuid4().hex[:6]}",
        "location": random.choice(CITIES),
        "startAt": "2025-08-01T10:00:00",
        "endAt": "2025-08-01T18:00:00",
        "owner": user_id
    }
    res = client.post("/events/", json=event_data)
    assert res.status_code == 200, f"Failed to create event: {res.text}"
    return res.json()


def register_attendance(user_id: str, event_id: str):
    attendance_data = {
        "user_id": user_id,
        "event_id": event_id
    }
    res = client.post("/attend/", json=attendance_data)
    assert res.status_code == 200, f"Failed to register attendance: {res.text}"


@pytest.mark.slow
def test_create_users_with_events_and_attendance():
    chunk_size = 100
    total_users = 1000
    total_events = 10
    continue_generate_from_user = 0

    user_res = client.post("/users/", json={
        "firstName": "Gina",
        "lastName": "Walker",
        "email": f"test{continue_generate_from_user}@email.com"
    })

    user_id = user_res.json()["id"]

    events = [create_event(i, user_id) for i in range(total_events)]

    progress_bar = tqdm(range(0, total_users, chunk_size), desc="User Creation", unit="chunk")

    for chunk_start in progress_bar:
        for i in range(chunk_start, min(chunk_start + chunk_size, total_users)):
            user_data = generate_random_user(i+continue_generate_from_user)
            res = client.post("/users/", json=user_data)
            assert res.status_code == 200, f"Failed to create user {i+continue_generate_from_user}: {res.text}"
            user = res.json()

            # Assign user to random events
            assigned_events = random.sample(events, k=random.randint(1, total_events))
            for event in assigned_events:
                register_attendance(user["id"], event["id"])

            # Optional: live update on last user/event
            progress_bar.set_postfix(user=user["firstName"], events=len(assigned_events))

        sleep(1)


    