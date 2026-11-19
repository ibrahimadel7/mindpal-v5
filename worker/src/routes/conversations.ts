import { Hono } from 'hono'
import { Database } from '../services/db'
import type { Conversation, Env } from '../types'

const conversationsRouter = new Hono<{ Bindings: Env }>()

conversationsRouter.get('/', async (c) => {
  const db = new Database(c.env.DB as unknown as D1Database)
  const userId = 1
  const conversations = await db.listConversations(userId)
  return c.json({ conversations })
})

conversationsRouter.post('/', async (c) => {
  const db = new Database(c.env.DB as unknown as D1Database)
  const body = await c.req.json<{ user_id?: number; title?: string }>()
  const userId = body.user_id ?? 1
  const title = body.title ?? 'New Reflection'
  const conversation = await db.createConversation(userId, title)
  return c.json(conversation, 201)
})

conversationsRouter.delete('/:id', async (c) => {
  const db = new Database(c.env.DB as unknown as D1Database)
  const id = parseInt(c.req.param('id'))
  const userId = 1
  await db.deleteConversation(id, userId)
  return c.body(null, 204)
})

conversationsRouter.post('/:id/close', async (c) => {
  const db = new Database(c.env.DB as unknown as D1Database)
  const id = parseInt(c.req.param('id'))
  const userId = 1
  const updated = await db.closeConversation(id, userId)
  if (!updated) {
    return c.json({ error: 'Conversation not found' }, 404)
  }
  return c.json(updated)
})

conversationsRouter.get('/:id/messages', async (c) => {
  const db = new Database(c.env.DB as unknown as D1Database)
  const id = parseInt(c.req.param('id'))
  const userId = 1
  const messages = await db.getMessages(id, userId)
  return c.json({ messages })
})

export default conversationsRouter
