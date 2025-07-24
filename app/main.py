from fastapi import FastAPI
from contextlib import asynccontextmanager
import logging

from app.services.db.init import create_tables
from app.routes import users, events, email, attendance, health, query_users
from fastapi_pagination import Page, add_pagination, paginate
from fastapi_pagination.utils import disable_installed_extensions_check
from app.config import settings

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
add_pagination(app)

# Routers
app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(events.router, prefix="/events", tags=["Events"])
app.include_router(attendance.router, prefix="/attend", tags=["Attendance"])
app.include_router(query_users.router, prefix="/search", tags=["Search"])
app.include_router(email.router, prefix="/email", tags=["Email"])
app.include_router(health.router)