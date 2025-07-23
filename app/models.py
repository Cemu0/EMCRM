from pydantic import BaseModel, EmailStr, Field, conint, field_validator, StringConstraints, PastDatetime, ConfigDict
from typing import Annotated, List, Optional
from datetime import datetime
from uuid import uuid4
from enum import Enum

# Custom base model for all app models
class AppBaseModel(BaseModel):
    model_config = ConfigDict(
        ser_json_timedelta="iso8601",
        ser_json_bytes="utf8",
        str_strip_whitespace=True,
    )

    def iso_dict(self, **kwargs):
        """Return dict with all datetimes as ISO strings."""
        return self.model_dump(mode="json", **kwargs)

# Aliases for convenience
IdStr = Annotated[str, Field(default_factory=lambda: str(uuid4()))]
Str50 = Annotated[str, StringConstraints(max_length=50, strip_whitespace=True)]
Str1000 = Annotated[str, StringConstraints(max_length=1000, strip_whitespace=True)]
SlugStr = Annotated[str, StringConstraints(pattern=r'^[a-z0-9]+(?:-[a-z0-9]+)*$', min_length=3, max_length=50)]
TitleStr = Annotated[str, StringConstraints(min_length=3, max_length=100, strip_whitespace=True)]
NonNegativeInt = Annotated[int, Field(ge=0)]

def clean_dynamodb_item(item: dict) -> dict:
    return {k: v for k, v in item.items() if v is not None}

class GenderEnum(str, Enum):
    male = "male"
    female = "female"
    other = "other"

class EmailStatusEnum(str, Enum):
    error = "error"
    pending = "pending"
    sending = "sending"
    sent = "sent"

class User(AppBaseModel):
    id: IdStr
    firstName: Str50
    lastName: Str50
    email: EmailStr
    phoneNumber: Optional[Annotated[str, StringConstraints(min_length=7, max_length=20)]] = None
    avatar: Optional[str] = None
    gender: Optional[GenderEnum] = None
    jobTitle: Optional[Str50] = None
    company: Optional[Str50] = None
    city: Optional[Str50] = None
    state: Optional[Str50] = None
    attendedCount: Annotated[int, Field(ge=0)] = 0
    hostedCount: Annotated[int, Field(ge=0)] = 0

    def to_dynamodb_item(self) -> dict:
        return clean_dynamodb_item({
            "PK": f"user#{self.id}",
            "SK": f"user#{self.id}",
            "type": "user",
            "firstName": self.firstName,
            "lastName": self.lastName,
            "email": str(self.email),
            "phoneNumber": self.phoneNumber,
            "avatar": self.avatar,
            "gender": self.gender,
            "jobTitle": self.jobTitle,
            "company": self.company,
            "city": self.city,
            "state": self.state,
            "attendedCount": self.attendedCount,
            "hostedCount": self.hostedCount,
        })
    def to_opensearch_doc(self):
        return self.model_dump(exclude_none=True)

class Event(AppBaseModel):
    id: IdStr
    slug: SlugStr
    title: TitleStr
    description: Optional[Annotated[str, StringConstraints(max_length=500)]] = None
    startAt: datetime
    endAt: datetime
    venue: Optional[Annotated[str, StringConstraints(max_length=200, strip_whitespace=True)]] = None
    maxCapacity: Optional[Annotated[int, Field(ge=1)]] = None
    owner: str
    hosts: List[str] = []

    @classmethod
    def validate_dates(cls, model):
        if model.endAt <= model.startAt:
            raise ValueError("endAt must be after startAt")
        return model

    def to_dynamodb_item(self) -> dict:
        return clean_dynamodb_item({
            "PK": f"event#{self.id}",
            "SK": f"event#{self.id}",
            "type": "event",
            "slug": self.slug,
            "title": self.title,
            "description": self.description,
            "startAt": self.startAt.isoformat(),
            "endAt": self.endAt.isoformat(),
            "venue": self.venue,
            "maxCapacity": self.maxCapacity,
            "owner": self.owner,
            "hosts": self.hosts,
        })

class EventAttendance(AppBaseModel):
    user_id: Str50
    event_id: Str50
    attended: Optional[str] = "yes"
    createdAt: datetime = Field(default_factory=datetime.now)
    
    def to_dynamodb_item(self) -> dict:
        iso_time = self.createdAt.isoformat()
        return {
                "PK": f"user#{self.user_id}",
                "SK": f"event#{self.event_id}",
                "type": "attendance",
                "attended": self.attended,
                "createdAt": iso_time,
            }

class UserFilter(AppBaseModel):
    company: Optional[str] = None
    jobTitle: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None

    minAttended: Optional[NonNegativeInt] = None
    maxAttended: Optional[NonNegativeInt] = None

    minHosted: Optional[NonNegativeInt] = None
    maxHosted: Optional[NonNegativeInt] = None

    @field_validator("maxAttended")
    @classmethod
    def validate_attended_range(cls, v, info):
        min_val = info.data.get("minAttended")
        if min_val is not None and v is not None and v < min_val:
            raise ValueError("maxAttended must be >= minAttended")
        return v

    @field_validator("maxHosted")
    @classmethod
    def validate_hosted_range(cls, v, info):
        min_val = info.data.get("minHosted")
        if min_val is not None and v is not None and v < min_val:
            raise ValueError("maxHosted must be >= minHosted")
        return v

class EmailRequest(AppBaseModel):
    email_id: IdStr
    filter: UserFilter #for storage purpose
    createdAt: datetime = Field(default_factory=datetime.now)
    totalRecipients: Optional[NonNegativeInt] = 0 #for storage purpose
    status: Optional[EmailStatusEnum] = EmailStatusEnum.sent
    subject: Str50
    body: Str1000
    def to_dynamodb_item(self) -> dict:
        iso_time = self.createdAt.isoformat()
        return {
                "PK": f"email#{self.email_id}",
                "SK": f"email#{self.email_id}",
                "type": "email_request",
                "filter": self.filter.model_dump(exclude_none=True),
                "createdAt": iso_time,
                "status": self.status,
                "totalRecipients": self.totalRecipients,
                "subject": self.subject,
                "body": self.body
            }

class Email(AppBaseModel):
    email_id: Str50
    user_id: Str50
    status: Optional[EmailStatusEnum] = None
    createdAt: datetime = Field(default_factory=datetime.now)
    def to_dynamodb_item(self) -> dict:
        iso_time = self.createdAt.isoformat()
        return {
                "PK": f"req_email#{self.email_id}",
                "SK": f"user#{self.user_id}",
                "type": "email_log",
                "status": self.status,
                "createdAt": iso_time,
            }