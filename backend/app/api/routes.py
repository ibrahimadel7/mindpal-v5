from fastapi import APIRouter

from app.api.chat import router as chat_router
from app.api.conversations import router as conversation_router
from app.api.insights import router as insights_router
from app.api.memory import router as memory_router
from app.api.recommendations import router as recommendations_router

router = APIRouter()


@router.get("/")
async def root() -> dict[str, str]:
    return {"status": "ok"}


router.include_router(chat_router)
router.include_router(conversation_router)
router.include_router(insights_router)
router.include_router(recommendations_router)
router.include_router(memory_router)
