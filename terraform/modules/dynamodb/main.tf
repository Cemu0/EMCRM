# DynamoDB Module
# Creates DynamoDB tables for CRM data and email data

# DynamoDB Tables
resource "aws_dynamodb_table" "crm_data" {
  name         = var.dynamodb_main_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "company"
    type = "S"
  }

  attribute {
    name = "jobTitle"
    type = "S"
  }

  attribute {
    name = "city_state"
    type = "S"
  }

  attribute {
    name = "type"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "slug"
    type = "S"
  }

  global_secondary_index {
    name            = "SKIndex"
    hash_key        = "SK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "CompanyIndex"
    hash_key        = "company"
    range_key       = "PK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "JobTitleIndex"
    hash_key        = "jobTitle"
    range_key       = "PK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "CityStateIndex"
    hash_key        = "city_state"
    range_key       = "PK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "TypeIndex"
    hash_key        = "type"
    range_key       = "PK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "SlugIndex"
    hash_key        = "slug"
    projection_type = "ALL"
  }

  tags = {
    Name        = "CRM Data Table"
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "email_data" {
  name         = var.dynamodb_email_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "type"
    type = "S"
  }

  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "PK"
    range_key       = "SK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "UserIndex"
    hash_key        = "SK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "TypeIndex"
    hash_key        = "type"
    projection_type = "ALL"
  }

  tags = {
    Name        = "Email Data Table"
    Environment = var.environment
  }
}