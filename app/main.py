from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from app.services.db.init import create_tables
from app.routes import users, events, email, attendance, health, query_users
from fastapi_pagination import Page, add_pagination, paginate
from fastapi_pagination.utils import disable_installed_extensions_check
from app.config import settings

# Conditional imports for authentication
# if settings.auth.enabled:
from app.middleware.auth import AuthMiddleware
from app.routes import auth

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.app.log_level),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(settings.app.app_name)

disable_installed_extensions_check()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    logger.info("Starting application...")
    if settings.auth.enabled:
        logger.info("Authentication enabled")
    else:
        logger.info("Authentication disabled - development mode")
    if not settings.app.production:
        create_tables()
    yield
    # Shutdown logic
    logger.info("Shutting down...")


app = FastAPI(
    title=settings.app.app_name,
    description="Event Management CRM System",
    version="1.0.0",
    lifespan=lifespan,
    debug=settings.app.debug
)

# Add CORS middleware when authentication is enabled
if settings.auth.enabled:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # Configure for your frontend domain
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Add authentication middleware
    app.add_middleware(AuthMiddleware)

add_pagination(app)

# Include authentication routes when enabled
if settings.auth.enabled:
    app.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# Routers
app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(events.router, prefix="/events", tags=["Events"])
app.include_router(attendance.router, prefix="/attend", tags=["Attendance"])
app.include_router(query_users.router, prefix="/search", tags=["Search"])
app.include_router(email.router, prefix="/email", tags=["Email"])
app.include_router(health.router)