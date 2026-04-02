from __future__ import annotations

from sqlalchemy import inspect, text
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import AsyncConnection


async def ensure_schema_updates(conn: AsyncConnection) -> None:
    """Apply additive schema updates for existing SQLite databases."""
    await conn.run_sync(_ensure_schema_updates)


def _ensure_schema_updates(sync_conn: Connection) -> None:
    inspector = inspect(sync_conn)
    tables = set(inspector.get_table_names())

    if "conversations" not in tables:
        return

    columns = {column["name"] for column in inspector.get_columns("conversations")}

    if "is_closed" not in columns:
        sync_conn.execute(text("ALTER TABLE conversations ADD COLUMN is_closed BOOLEAN NOT NULL DEFAULT 0"))

    if "closed_at" not in columns:
        sync_conn.execute(text("ALTER TABLE conversations ADD COLUMN closed_at DATETIME"))

    if "last_intervention_at" not in columns:
        sync_conn.execute(text("ALTER TABLE conversations ADD COLUMN last_intervention_at DATETIME"))

    if "message_count_since_last_intervention" not in columns:
        sync_conn.execute(
            text("ALTER TABLE conversations ADD COLUMN message_count_since_last_intervention INTEGER NOT NULL DEFAULT 0")
        )

    sync_conn.execute(
        text(
            """
            CREATE TABLE IF NOT EXISTS recommendation_batches (
                id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL,
                category VARCHAR(32) NOT NULL,
                batch_date DATE NOT NULL,
                is_active BOOLEAN NOT NULL DEFAULT 1,
                context_summary_json JSON NOT NULL DEFAULT '{}',
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
            )
            """
        )
    )
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_recommendation_batches_user_id ON recommendation_batches (user_id)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_recommendation_batches_category ON recommendation_batches (category)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_recommendation_batches_batch_date ON recommendation_batches (batch_date)"))

    sync_conn.execute(
        text(
            """
            CREATE TABLE IF NOT EXISTS recommendation_items (
                id INTEGER PRIMARY KEY,
                batch_id INTEGER NOT NULL,
                position INTEGER NOT NULL,
                category VARCHAR(32) NOT NULL,
                kind VARCHAR(32) NOT NULL,
                title VARCHAR(255) NOT NULL,
                rationale TEXT NOT NULL,
                action_payload_json JSON NOT NULL DEFAULT '{}',
                estimated_duration_minutes INTEGER,
                follow_up_text TEXT,
                status VARCHAR(32) NOT NULL DEFAULT 'pending',
                completed_at DATETIME,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(batch_id) REFERENCES recommendation_batches(id) ON DELETE CASCADE
            )
            """
        )
    )
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_recommendation_items_batch_id ON recommendation_items (batch_id)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_recommendation_items_kind ON recommendation_items (kind)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_recommendation_items_status ON recommendation_items (status)"))

    sync_conn.execute(
        text(
            """
            CREATE TABLE IF NOT EXISTS recommendation_interactions (
                id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL,
                batch_id INTEGER,
                item_id INTEGER,
                event_type VARCHAR(64) NOT NULL,
                event_payload_json JSON NOT NULL DEFAULT '{}',
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY(batch_id) REFERENCES recommendation_batches(id) ON DELETE CASCADE,
                FOREIGN KEY(item_id) REFERENCES recommendation_items(id) ON DELETE CASCADE
            )
            """
        )
    )
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_recommendation_interactions_user_id ON recommendation_interactions (user_id)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_recommendation_interactions_item_id ON recommendation_interactions (item_id)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_recommendation_interactions_event_type ON recommendation_interactions (event_type)"))

    sync_conn.execute(
        text(
            """
            CREATE TABLE IF NOT EXISTS user_habits (
                id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL,
                source_recommendation_item_id INTEGER,
                name VARCHAR(255) NOT NULL,
                category VARCHAR(32) NOT NULL,
                cue_text TEXT,
                reason_text TEXT,
                is_active BOOLEAN NOT NULL DEFAULT 1,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                archived_at DATETIME,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY(source_recommendation_item_id) REFERENCES recommendation_items(id) ON DELETE SET NULL
            )
            """
        )
    )
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_habits_user_id ON user_habits (user_id)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_habits_category ON user_habits (category)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_habits_is_active ON user_habits (is_active)"))

    sync_conn.execute(
        text(
            """
            CREATE TABLE IF NOT EXISTS user_habit_checks (
                id INTEGER PRIMARY KEY,
                habit_id INTEGER NOT NULL,
                check_date DATE NOT NULL,
                is_completed BOOLEAN NOT NULL DEFAULT 1,
                completed_at DATETIME,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(habit_id) REFERENCES user_habits(id) ON DELETE CASCADE
            )
            """
        )
    )
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_habit_checks_habit_id ON user_habit_checks (habit_id)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_habit_checks_check_date ON user_habit_checks (check_date)"))
    sync_conn.execute(
        text(
            "CREATE UNIQUE INDEX IF NOT EXISTS ux_user_habit_checks_habit_date ON user_habit_checks (habit_id, check_date)"
        )
    )

    sync_conn.execute(
        text(
            """
            CREATE TABLE IF NOT EXISTS user_memory (
                id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL UNIQUE,
                is_paused BOOLEAN NOT NULL DEFAULT 0,
                context_json JSON NOT NULL DEFAULT '{}',
                habits_json JSON NOT NULL DEFAULT '[]',
                emotions_json JSON NOT NULL DEFAULT '[]',
                goals_json JSON NOT NULL DEFAULT '[]',
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                last_summarized_at DATETIME,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
            )
            """
        )
    )
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_memory_user_id ON user_memory (user_id)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_memory_is_paused ON user_memory (is_paused)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_memory_updated_at ON user_memory (updated_at)"))

    sync_conn.execute(
        text(
            """
            CREATE TABLE IF NOT EXISTS user_memory_entries (
                id INTEGER PRIMARY KEY,
                user_memory_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                category VARCHAR(32) NOT NULL,
                content TEXT NOT NULL,
                embedding_json JSON NOT NULL DEFAULT '[]',
                vector_id VARCHAR(128),
                relevance_score FLOAT NOT NULL DEFAULT 0.5,
                emotional_significance FLOAT NOT NULL DEFAULT 0.5,
                recurrence_count INTEGER NOT NULL DEFAULT 1,
                source_conversation_id INTEGER,
                is_active BOOLEAN NOT NULL DEFAULT 1,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(user_memory_id) REFERENCES user_memory(id) ON DELETE CASCADE,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY(source_conversation_id) REFERENCES conversations(id) ON DELETE SET NULL
            )
            """
        )
    )
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_memory_entries_user_id ON user_memory_entries (user_id)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_memory_entries_category ON user_memory_entries (category)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_memory_entries_is_active ON user_memory_entries (is_active)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_memory_entries_updated_at ON user_memory_entries (updated_at)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_memory_entries_vector_id ON user_memory_entries (vector_id)"))

    sync_conn.execute(
        text(
            """
            CREATE TABLE IF NOT EXISTS user_memory_audit_logs (
                id INTEGER PRIMARY KEY,
                entry_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                old_content TEXT,
                new_content TEXT,
                old_category VARCHAR(32),
                new_category VARCHAR(32),
                reason VARCHAR(64) NOT NULL DEFAULT 'update',
                changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(entry_id) REFERENCES user_memory_entries(id) ON DELETE CASCADE,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
                UNIQUE(entry_id, changed_at)
            )
            """
        )
    )
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_memory_audit_logs_entry_id ON user_memory_audit_logs (entry_id)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_memory_audit_logs_user_id ON user_memory_audit_logs (user_id)"))
    sync_conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_memory_audit_logs_changed_at ON user_memory_audit_logs (changed_at)"))
