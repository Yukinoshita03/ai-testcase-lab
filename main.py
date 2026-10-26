from contextlib import asynccontextmanager

from fastapi import FastAPI

from database import close_db, init_db
from router.router import api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()

    try:
        yield
    finally:
        close_db()

app = FastAPI(lifespan=lifespan)
app.include_router(api_router)
