from pydantic_settings import BaseSettings
from pydantic import Field
from typing import Optional


class DatabaseSettings(BaseSettings):
    """Database configuration settings"""
    aws_region: str = Field(default="us-west-2", description="AWS Region")
    dynamodb_endpoint: Optional[str] = Field(default="http://localhost:8000", description="DynamoDB endpoint URL")
    aws_access_key_id: str = Field(default="dummy", description="AWS Access Key ID")
    aws_secret_access_key: str = Field(default="dummy", description="AWS Secret Access Key")
    main_table_name: str = Field(default="crm_data", description="Main DynamoDB table name")
    email_table_name: str = Field(default="email_data", description="Email DynamoDB table name")
    max_retries: int = Field(default=2, description="Maximum number of retry attempts")
    connect_timeout: int = Field(default=5, description="Connection timeout in seconds")
    read_timeout: int = Field(default=10, description="Read timeout in seconds")
    max_pool_connections: int = Field(default=10, description="Maximum number of connections in the pool")
    
    class Config:
        env_prefix = "DB_"
        env_file = ".env"
        env_file_encoding = "utf-8"
        env_ignore_empty = True
        extra = 'ignore' 


class OpenSearchSettings(BaseSettings):
    """OpenSearch configuration settings"""
    mode: str = Field(default="local", description="OpenSearch mode (local or cloud)")
    endpoint: Optional[str] = Field(default="http://localhost:9200", description="OpenSearch endpoint URL")
    host: Optional[str] = Field(default=None, description="OpenSearch host for cloud mode")
    username: str = Field(default="admin", description="OpenSearch username")
    password: str = Field(default="aStrongPassw0rd!", description="OpenSearch password")
    use_ssl: bool = Field(default=False, description="Whether to use SSL")
    verify_certs: bool = Field(default=False, description="Whether to verify certificates")
    
    class Config:
        env_prefix = "OPENSEARCH_"
        env_file = ".env"
        env_file_encoding = "utf-8"
        env_ignore_empty = True
        extra = 'ignore'


class AppSettings(BaseSettings):
    """Application configuration settings"""
    app_name: str = Field(default="EMCRM", description="Application name")
    debug: bool = Field(default=False, description="Debug mode")
    api_port: int = Field(default=8080, description="API port")
    api_host: str = Field(default="0.0.0.0", description="API host")
    log_level: str = Field(default="INFO", description="Logging level")
    
    class Config:
        env_prefix = "APP_"
        env_file = ".env"
        env_file_encoding = "utf-8"
        env_ignore_empty = True
        extra = 'ignore'


class Settings(BaseSettings):
    """Main settings class that combines all settings"""
    database: DatabaseSettings = Field(default_factory=DatabaseSettings)
    opensearch: OpenSearchSettings = Field(default_factory=OpenSearchSettings)
    app: AppSettings = Field(default_factory=AppSettings)
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        env_ignore_empty = True
        extra = 'ignore'


# Create a global settings instance
settings = Settings()