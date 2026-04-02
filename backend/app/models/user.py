from datetime import datetime

from sqlalchemy import DateTime, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    conversations = relationship("Conversation", back_populates="user", cascade="all, delete-orphan")
    chat_memories = relationship("UserChatMemory", back_populates="user", cascade="all, delete-orphan")
    recommendation_batches = relationship("RecommendationBatch", back_populates="user", cascade="all, delete-orphan")
    recommendation_interactions = relationship(
        "RecommendationInteraction",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    habits = relationship("UserHabit", back_populates="user", cascade="all, delete-orphan")
    memory_profile = relationship("UserMemory", back_populates="user", uselist=False, cascade="all, delete-orphan")
    memory_entries = relationship("UserMemoryEntry", back_populates="user", cascade="all, delete-orphan")
