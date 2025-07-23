from fastapi import FastAPI
from contextlib import asynccontextmanager

from .db.init import create_tables
from .routes import users, events, email, attendance, health
from .query import filter_users
from fastapi_pagination import Page, add_pagination, paginate
from fastapi_pagination.utils import disable_installed_extensions_check

disable_installed_extensions_check()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    create_tables()
    yield
    # Shutdown logic
    print("Shutting down...")


app = FastAPI(lifespan=lifespan)
add_pagination(app)

# Routers
app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(events.router, prefix="/events", tags=["Events"])
app.include_router(attendance.router, prefix="/attend", tags=["Attendance"])
app.include_router(filter_users.router, prefix="/search", tags=["Search"])
app.include_router(email.router, prefix="/email", tags=["Email"])
app.include_router(health.router)