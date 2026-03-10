from sqlalchemy import ForeignKey, Integer, JSON, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base


class MessageAnalysis(Base):
    __tablename__ = "message_analysis"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    message_id: Mapped[int] = mapped_column(
        ForeignKey("messages.id", ondelete="CASCADE"), nullable=False, unique=True, index=True
    )
    emotions_json: Mapped[dict] = mapped_column(JSON, default=dict)
    habits_json: Mapped[dict] = mapped_column(JSON, default=dict)
    detected_topics_json: Mapped[dict] = mapped_column(JSON, default=dict)
    time_of_day: Mapped[str] = mapped_column(String(16), nullable=False)
    day_of_week: Mapped[str] = mapped_column(String(16), nullable=False)

    message = relationship("Message", back_populates="analysis")
