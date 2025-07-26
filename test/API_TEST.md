# EMCRM API Testing Guide

This guide explains how to test the EMCRM API using the provided Postman collection.

## Prerequisites

1. **Postman** installed on your machine
2. **EMCRM API** running locally or deployed
3. **Authentication** setup (if required)

## Setup

### 1. Import the Collection

1. Open Postman
2. Click "Import" button
3. Select the file: `simple_api_test.postman_collection.json`
4. The collection "simple_api_test" will be imported

### 2. Environment Variables

Set up the following environment variables in Postman:

- `baseUrl`: Your API base URL (e.g., `http://localhost:8000` for local development)
- `auth_token`: Authentication cookie/token (if authentication is enabled)
- `user_id`: Will be automatically set by the "Create User" test
- `event_id`: Will be automatically set by the "Create Event" test
- `email_id`: Will be automatically set by email-related tests

### 3. Authentication (if enabled)

1. Open your browser and navigate to the authentication endpoint (e.g., `http://localhost:8000/auth/login`)
2. Complete the login process
3. Copy the authentication cookie from browser developer tools
4. Set it as the `auth_token` environment variable in Postman should look like "auth_session=.eJxNVceu5..."

## Test Scenarios

The collection includes comprehensive test scenarios for all API endpoints:

### User Management

1. **Create User** - Creates a new user with random data
   - ✅ Validates 200 status code
   - ✅ Sets `user_id` environment variable

2. **Get User** - Retrieves the created user
   - ✅ Validates 200 status code
   - ✅ Validates job title is "CEO"

3. **Update User** - Updates user information
   - ✅ Validates 200 status code
   - ✅ Validates job title changed to "CFO"

4. **Delete User** - Removes the user
   - ✅ Validates 200 status code

5. **Get User (should fail)** - Confirms user deletion
   - ✅ Validates 404 status code

### Event Management

1. **Create Event** - Creates a new event
2. **Get Event** - Retrieves event details
3. **Update Event** - Modifies event information
4. **Delete Event** - Removes the event

### Attendance Management

1. **Create Attendance** - Records user attendance for an event
2. **Get User Attendance** - Lists events attended by a user
3. **Get Event Attendance** - Lists users who attended an event

### Email System

1. **Send Email** - Sends emails to filtered users
2. **Get Email Requests** - Lists email sending requests
3. **Get Email Status** - Checks email delivery status

### User Queries

1. **Query Users** - Search and filter users
2. **Get All Users** - Retrieve paginated user list

## Running Tests

### Option 1: Run Individual Requests

1. Select any request from the collection
2. Click "Send"
3. Check the response and test results in the "Test Results" tab

### Option 2: Run Entire Collection

1. Right-click on the "simple_api_test" collection
2. Select "Run collection"
3. Configure test settings:
   - **Iterations**: 1 (or more for load testing)
   - **Delay**: 100ms between requests (to avoid overwhelming the API)
4. Click "Run simple_api_test"
5. Monitor the test results in real-time

### Option 3: Run Specific Folders

1. Expand the collection to see folders (user, event, attendance, etc.)
2. Right-click on any folder
3. Select "Run folder"
4. Follow the same configuration as above

## Test Data

The collection uses Postman's dynamic variables for realistic test data:

- `{{$randomFirstName}}` - Random first name
- `{{$randomLastName}}` - Random last name
- `{{$randomEmail}}` - Random email address
- `{{$randomPhoneNumber}}` - Random phone number
- `{{$randomCompanyName}}` - Random company name
- `{{$randomCity}}` - Random city name

## Expected Results

✅ **All tests should pass** if the API is working correctly

❌ **Common failure scenarios:**
- Authentication issues (401/403 errors)
- Database connection problems (500 errors)
- Validation errors (422 errors)
- Missing dependencies (404 errors)

## Troubleshooting

### Authentication Issues
- Ensure `auth_token` is set correctly
- Check if the token has expired
- Verify authentication is properly configured

### Connection Issues
- Verify `baseUrl` is correct
- Ensure the API server is running
- Check network connectivity

### Test Failures
- Check the "Test Results" tab for specific error messages
- Review the response body for error details
- Ensure all required environment variables are set

### Database Issues
- Verify DynamoDB and OpenSearch are running (for local development)
- Check database connection settings
- Ensure proper IAM permissions (for AWS deployment)

## Load Testing

To perform basic load testing:

1. Run the collection with multiple iterations (e.g., 10-50)
2. Set appropriate delays between requests (100-500ms)
3. Monitor response times and error rates
4. Check server logs for any issues

## Notes

- The collection includes automatic cleanup (delete operations)
- Tests are designed to run independently
- Some tests depend on previous tests (e.g., "Get User" depends on "Create User")
- Environment variables are automatically managed by the test scripts