from __future__ import annotations

from datetime import datetime
from enum import Enum

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base


class MemoryCategory(str, Enum):
    HABIT = "habit"
    EMOTION = "emotion"
    GOAL = "goal"
    PREFERENCE = "preference"


class UserMemory(Base):
    __tablename__ = "user_memory"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        unique=True,
    )
    is_paused: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
    context_json: Mapped[dict] = mapped_column(JSON, default=dict, nullable=False)
    habits_json: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    emotions_json: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    goals_json: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    last_summarized_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    user = relationship("User", back_populates="memory_profile")
    entries = relationship("UserMemoryEntry", back_populates="memory", cascade="all, delete-orphan")


class UserMemoryEntry(Base):
    __tablename__ = "user_memory_entries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_memory_id: Mapped[int] = mapped_column(
        ForeignKey("user_memory.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    category: Mapped[str] = mapped_column(String(32), nullable=False, index=True)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    embedding_json: Mapped[list[float]] = mapped_column(JSON, default=list, nullable=False)
    vector_id: Mapped[str | None] = mapped_column(String(128), nullable=True, index=True)
    relevance_score: Mapped[float] = mapped_column(Float, default=0.5, nullable=False)
    emotional_significance: Mapped[float] = mapped_column(Float, default=0.5, nullable=False)
    recurrence_count: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    source_conversation_id: Mapped[int | None] = mapped_column(
        ForeignKey("conversations.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False, index=True)

    memory = relationship("UserMemory", back_populates="entries")
    user = relationship("User", back_populates="memory_entries")
    source_conversation = relationship("Conversation", back_populates="memory_entries")
    audit_logs = relationship("UserMemoryAuditLog", back_populates="entry", cascade="all, delete-orphan")


class UserMemoryAuditLog(Base):
    __tablename__ = "user_memory_audit_logs"
    __table_args__ = (
        UniqueConstraint("entry_id", "changed_at", name="uq_memory_audit_entry_changed_at"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    entry_id: Mapped[int] = mapped_column(
        ForeignKey("user_memory_entries.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    old_content: Mapped[str | None] = mapped_column(Text, nullable=True)
    new_content: Mapped[str | None] = mapped_column(Text, nullable=True)
    old_category: Mapped[str | None] = mapped_column(String(32), nullable=True)
    new_category: Mapped[str | None] = mapped_column(String(32), nullable=True)
    reason: Mapped[str] = mapped_column(String(64), nullable=False, default="update")
    changed_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False, index=True)

    entry = relationship("UserMemoryEntry", back_populates="audit_logs")
