
# EMCRM API Documentation

> **Note**: For interactive API documentation, visit `/docs` endpoint when the server is running. OpenAPI specification is also available at `/openapi.json`.

## Base URL
- **Local Development**: `http://localhost:8000`
- **Production**: Your deployed domain

## Authentication

Authentication is optional and can be enabled/disabled via environment variables:
- When enabled: Uses AWS Cognito OAuth2
- When disabled: All endpoints are publicly accessible

## API Endpoints

### User Management (`/users`)

#### Create User
- **POST** `/users/`
- **Body**: User object with required fields (firstName, lastName, email)
- **Response**: Created user with generated ID
- **Status Codes**: 201 (Created), 400 (Validation Error), 409 (Email Conflict)

#### Get User
- **GET** `/users/{user_id}`
- **Response**: User details including attendance/hosting counts
- **Status Codes**: 200 (OK), 404 (Not Found)

#### Update User
- **PUT** `/users/{user_id}`
- **Body**: Partial or complete user object
- **Response**: Updated user details
- **Status Codes**: 200 (OK), 404 (Not Found), 400 (Validation Error)

#### Delete User
- **DELETE** `/users/{user_id}`
- **Response**: Confirmation message
- **Status Codes**: 200 (OK), 404 (Not Found)

#### List Users
- **GET** `/users/`
- **Query Parameters**: 
  - `limit` (default: 50, max: 100)
  - `last_evaluated_key` (for pagination)
- **Response**: Paginated list of users
- **Status Codes**: 200 (OK)

### Event Management (`/events`)

#### Create Event
- **POST** `/events/`
- **Body**: Event object with required fields (title, startAt, endAt, venue)
- **Response**: Created event with generated ID and slug
- **Status Codes**: 201 (Created), 400 (Validation Error)

#### Get Event
- **GET** `/events/{event_id}`
- **Response**: Event details including attendee count
- **Status Codes**: 200 (OK), 404 (Not Found)

#### Update Event
- **PUT** `/events/{event_id}`
- **Body**: Partial or complete event object
- **Response**: Updated event details
- **Status Codes**: 200 (OK), 404 (Not Found), 400 (Validation Error)

#### Delete Event
- **DELETE** `/events/{event_id}`
- **Response**: Confirmation message
- **Status Codes**: 200 (OK), 404 (Not Found)

#### List Events
- **GET** `/events/`
- **Query Parameters**: 
  - `limit` (default: 50, max: 100)
  - `last_evaluated_key` (for pagination)
- **Response**: Paginated list of events
- **Status Codes**: 200 (OK)

### Attendance Management (`/attend`)

#### Create Attendance
- **POST** `/attend/`
- **Body**: `{"user_id": "string", "event_id": "string"}`
- **Response**: Attendance record with automatic user count increment
- **Status Codes**: 201 (Created), 400 (Validation Error), 409 (Already Attending)

#### Get User's Events
- **GET** `/attend/user/{user_id}`
- **Response**: List of events the user is attending
- **Status Codes**: 200 (OK), 404 (User Not Found)

#### Get Event Attendees
- **GET** `/attend/event/{event_id}`
- **Response**: List of users attending the event
- **Status Codes**: 200 (OK), 404 (Event Not Found)

### User Search (`/search`)

#### Advanced User Search
- **POST** `/search/users`
- **Body**: UserFilter object with optional criteria:
  - `company`, `jobTitle`, `city`, `state`
  - `minAttended`, `maxAttended`, `minHosted`, `maxHosted`
- **Response**: Filtered list of users
- **Status Codes**: 200 (OK), 400 (Invalid Filter)

#### Basic User Search
- **GET** `/search/users`
- **Query Parameters**: Basic search terms
- **Response**: List of matching users
- **Status Codes**: 200 (OK)

### Email System (`/email`)

#### Send Bulk Email
- **POST** `/email/send`
- **Body**: EmailRequest object with filter criteria, subject, and body
- **Response**: Email request details with recipient count
- **Status Codes**: 201 (Created), 400 (Validation Error)

#### List Email Requests
- **GET** `/email/requests`
- **Query Parameters**: 
  - `limit` (default: 50)
  - `last_evaluated_key` (for pagination)
- **Response**: Paginated list of email campaigns
- **Status Codes**: 200 (OK)

#### Get Email Request
- **GET** `/email/requests/{email_id}`
- **Response**: Specific email request details
- **Status Codes**: 200 (OK), 404 (Not Found)

#### Get Email Status by Request
- **GET** `/email/status/{email_id}`
- **Response**: Delivery status for all recipients of an email campaign
- **Status Codes**: 200 (OK), 404 (Not Found)

#### Get User Email History
- **GET** `/email/status/user/{user_id}`
- **Response**: All emails sent to a specific user
- **Status Codes**: 200 (OK), 404 (User Not Found)

### Authentication (`/auth`) - Optional

> **Note**: These endpoints are only available when Cognito authentication is enabled.

#### Login
- **GET** `/auth/login`
- **Response**: Redirect to Cognito login page
- **Status Codes**: 302 (Redirect)

#### OAuth Callback
- **GET** `/auth/callback`
- **Query Parameters**: OAuth authorization code
- **Response**: JWT token and user info
- **Status Codes**: 200 (OK), 400 (Invalid Code)

#### Logout
- **POST** `/auth/logout`
- **Response**: Logout confirmation
- **Status Codes**: 200 (OK)

#### Get Current User
- **GET** `/auth/user`
- **Headers**: `Authorization: Bearer <token>`
- **Response**: Current authenticated user info
- **Status Codes**: 200 (OK), 401 (Unauthorized)

### Health Check

#### System Health
- **GET** `/health`
- **Response**: System status including database and search connectivity
- **Status Codes**: 200 (Healthy), 503 (Unhealthy)

## Response Format

All API responses follow a consistent format:

```json
{
  "data": {}, // Response data
  "message": "string", // Success/error message
  "status": "success|error"
}
```

## Error Handling

Standard HTTP status codes are used:
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation errors)
- `401` - Unauthorized
- `404` - Not Found
- `409` - Conflict (duplicate data)
- `500` - Internal Server Error

## Rate Limiting

Currently no rate limiting is implemented. This is planned for future releases.

## Testing

Use the provided Postman collection at `test/simple_api_test.postman_collection.json` for comprehensive API testing.