"""
Test to verify ORM cascade deletion works correctly.
Tests that deleting a conversation properly cascades to delete all related messages and analysis records.
"""
from __future__ import annotations

import asyncio
import sys
from datetime import datetime
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.database.base import Base
from app.models.conversation import Conversation
from app.models.message import Message, MessageRole
from app.models.message_analysis import MessageAnalysis
from app.models.user import User


async def test_deletion_cascade():
    """
    Test that deleting a conversation cascades to delete all related messages and analysis.
    This verifies the ORM cascade configuration is working correctly.
    """
    # Create in-memory SQLite database for testing
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)
    
    # Create all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Create session factory
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        # Create test user
        user = User(id=1)
        session.add(user)
        await session.flush()
        
        # Create conversation
        conversation = Conversation(user_id=1, title="Test Conversation")
        session.add(conversation)
        await session.flush()
        conversation_id = conversation.id
        
        # Create messages
        message1 = Message(conversation_id=conversation_id, role=MessageRole.USER, content="Message 1")
        message2 = Message(conversation_id=conversation_id, role=MessageRole.ASSISTANT, content="Message 2")
        session.add(message1)
        session.add(message2)
        await session.flush()
        
        # Create message analysis records
        analysis1 = MessageAnalysis(
            message_id=message1.id,
            emotions_json={"emotions": [{"label": "joy", "score": 0.8}]},
            habits_json={"habits": [{"habit": "exercise"}]},
            time_of_day="morning",
            day_of_week="Monday"
        )
        analysis2 = MessageAnalysis(
            message_id=message2.id,
            emotions_json={"emotions": [{"label": "sadness", "score": 0.6}]},
            habits_json={"habits": [{"habit": "reading"}]},
            time_of_day="evening",
            day_of_week="Monday"
        )
        session.add(analysis1)
        session.add(analysis2)
        await session.commit()
        
        # Verify data was created
        # Count records before deletion
        from sqlalchemy import select, func
        
        convo_count_before = (await session.execute(select(func.count(Conversation.id)))).scalar()
        msg_count_before = (await session.execute(select(func.count(Message.id)))).scalar()
        analysis_count_before = (await session.execute(select(func.count(MessageAnalysis.id)))).scalar()
        
        print(f"Before deletion:")
        print(f"  Conversations: {convo_count_before}")
        print(f"  Messages: {msg_count_before}")
        print(f"  Analysis records: {analysis_count_before}")
        
        assert convo_count_before == 1, f"Expected 1 conversation, got {convo_count_before}"
        assert msg_count_before == 2, f"Expected 2 messages, got {msg_count_before}"
        assert analysis_count_before == 2, f"Expected 2 analysis records, got {analysis_count_before}"
        
        # Now test deletion - use the same pattern as the API
        conversation_to_delete = (await session.execute(select(Conversation).where(Conversation.id == conversation_id))).scalar_one_or_none()
        assert conversation_to_delete is not None, "Conversation not found"
        
        # Delete using ORM (this is what our fix does)
        await session.delete(conversation_to_delete)
        await session.commit()
        
        # Verify all related records were deleted
        convo_count_after = (await session.execute(select(func.count(Conversation.id)))).scalar()
        msg_count_after = (await session.execute(select(func.count(Message.id)))).scalar()
        analysis_count_after = (await session.execute(select(func.count(MessageAnalysis.id)))).scalar()
        
        print(f"\nAfter deletion:")
        print(f"  Conversations: {convo_count_after}")
        print(f"  Messages: {msg_count_after}")
        print(f"  Analysis records: {analysis_count_after}")
        
        assert convo_count_after == 0, f"Expected 0 conversations after deletion, got {convo_count_after}"
        assert msg_count_after == 0, f"Expected 0 messages after deletion, got {msg_count_after}"
        assert analysis_count_after == 0, f"Expected 0 analysis records after deletion, got {analysis_count_after}"
        
        print("\n✓ Deletion cascade test PASSED - all related records were deleted!")
    
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(test_deletion_cascade())
