from fastapi import APIRouter

from app.api.chat import router as chat_router
from app.api.conversations import router as conversation_router
from app.api.insights import router as insights_router

router = APIRouter()
router.include_router(chat_router)
router.include_router(conversation_router)
router.include_router(insights_router)
