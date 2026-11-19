import type { D1Database } from '@cloudflare/workers-types'
import type { Conversation, Message } from '../types'

export class Database {
  constructor(private db: D1Database) {}

  async getConversation(id: number, userId: number): Promise<Conversation | null> {
    const result = await this.db
      .prepare('SELECT * FROM conversations WHERE id = ? AND user_id = ?')
      .bind(id, userId)
      .first<Conversation>()

    return result ?? null
  }

  async createConversation(userId: number, title: string): Promise<Conversation> {
    const result = await this.db
      .prepare(
        'INSERT INTO conversations (user_id, title) VALUES (?, ?) RETURNING id, user_id, title, is_closed, closed_at, created_at'
      )
      .bind(userId, title)
      .run()

    // D1 RETURNING support may vary; fall back to select if needed
    const meta = result.meta
    if (meta?.last_row_id) {
      const created = await this.db
        .prepare('SELECT * FROM conversations WHERE id = ? AND user_id = ?')
        .bind(meta.last_row_id, userId)
        .first<Conversation>()
      return created!
    }

    throw new Error('Failed to create conversation')
  }

  async deleteConversation(id: number, userId: number): Promise<void> {
    await this.db.prepare('DELETE FROM conversations WHERE id = ? AND user_id = ?').bind(id, userId).run()
  }

  async closeConversation(id: number, userId: number): Promise<Conversation | null> {
    const now = new Date().toISOString()
    await this.db
      .prepare('UPDATE conversations SET is_closed = 1, closed_at = ? WHERE id = ? AND user_id = ?')
      .bind(now, id, userId)
      .run()
    return this.getConversation(id, userId)
  }

  async getMessages(conversationId: number, userId: number): Promise<Message[]> {
    const result = await this.db
      .prepare(
        'SELECT m.* FROM messages m JOIN conversations c ON m.conversation_id = c.id WHERE m.conversation_id = ? AND c.user_id = ? ORDER BY m.timestamp ASC'
      )
      .bind(conversationId, userId)
      .all<Message>()

    return result.results ?? []
  }

  async createMessage(
    conversationId: number,
    role: string,
    content: string
  ): Promise<Message> {
    const now = new Date().toISOString()
    const result = await this.db
      .prepare(
        'INSERT INTO messages (conversation_id, role, content, timestamp) VALUES (?, ?, ?, ?) RETURNING id, conversation_id, role, content, timestamp'
      )
      .bind(conversationId, role, content, now)
      .run()

    const meta = result.meta
    if (meta?.last_row_id) {
      return {
        id: meta.last_row_id,
        conversationId,
        role,
        content,
        timestamp: now,
      }
    }

    throw new Error('Failed to create message')
  }

  async listConversations(userId: number): Promise<Conversation[]> {
    const result = await this.db
      .prepare('SELECT * FROM conversations WHERE user_id = ? ORDER BY created_at DESC')
      .bind(userId)
      .all<Conversation>()

    return result.results ?? []
  }
}
