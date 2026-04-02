"""
Migration helper to add intervention tracking columns to conversations table.

Run this script if your database needs the new columns:
    python scripts/migrate_add_intervention_tracking.py
"""
from __future__ import annotations

import sqlite3
from pathlib import Path


def run_migration() -> None:
    """Add intervention tracking columns to conversations table if not present."""
    db_path = Path(__file__).parent.parent / "mindpal.db"
    
    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()
    
    try:
        # Check if columns already exist
        cursor.execute("PRAGMA table_info(conversations)")
        columns = {row[1] for row in cursor.fetchall()}
        
        if "last_intervention_at" not in columns:
            cursor.execute(
                "ALTER TABLE conversations ADD COLUMN last_intervention_at DATETIME NULL"
            )
            print("✓ Added last_intervention_at column")
        else:
            print("✓ last_intervention_at column already exists")
        
        if "message_count_since_last_intervention" not in columns:
            cursor.execute(
                "ALTER TABLE conversations ADD COLUMN message_count_since_last_intervention INTEGER DEFAULT 0 NOT NULL"
            )
            print("✓ Added message_count_since_last_intervention column")
        else:
            print("✓ message_count_since_last_intervention column already exists")
        
        conn.commit()
        print("✓ Migration complete")
    
    except Exception as e:
        print(f"✗ Migration failed: {e}")
        conn.rollback()
    finally:
        conn.close()


if __name__ == "__main__":
    run_migration()
