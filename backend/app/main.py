from contextlib import asynccontextmanager
import logging

from fastapi import FastAPI

from app.api.routes import router as api_router
from app.config import get_settings
from app.database.base import Base
from app.database.session import engine
from app import models  # noqa: F401
from app.rag.knowledge_base_seed import seed_knowledge_base
from app.services.graph_service import GraphService

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
    """Initialize persistent resources on startup."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    graph_service = GraphService()
    graph_service.load_state()

    if settings.groq_api_key:
        await seed_knowledge_base()
    else:
        logger.warning("Skipping knowledge base seeding because GROQ_API_KEY is not configured")
    yield
    graph_service.save_state()


settings = get_settings()
app = FastAPI(title=settings.app_name, lifespan=lifespan)
app.include_router(api_router)
