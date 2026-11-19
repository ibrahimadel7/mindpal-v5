-- MindPal Database Schema for Cloudflare D1
-- Run: wrangler d1 execute mindpal-db --remote --file=./migrations/001_initial.sql

CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT,
  display_name TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS conversations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL DEFAULT 1,
  title TEXT,
  is_closed INTEGER DEFAULT 0,
  closed_at TEXT,
  last_intervention_at TEXT,
  message_count_since_last_intervention INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  conversation_id INTEGER NOT NULL REFERENCES conversations(id),
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  timestamp TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Insert default single-tenant user
INSERT OR IGNORE INTO users (id, email, display_name) VALUES (1, 'user@mindpal.local', 'MindPal User');

-- Insert default conversation
INSERT OR IGNORE INTO conversations (id, user_id, title, is_closed) VALUES (1, 1, 'New Reflection', 0);
