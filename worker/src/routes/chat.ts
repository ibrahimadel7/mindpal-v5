import { Hono } from 'hono'
import { corsMiddleware } from './middleware/cors'
import { securityHeadersMiddleware } from './middleware/security-headers'
import { rateLimitMiddleware } from './middleware/rate-limit'
import { Database } from '../services/db.ts'
import { GroqService } from '../services/groq.ts'
import type { ChatRequest, ChatResponse, ErrorResponse } from './types'

const chatRouter = new Hono()

chatRouter.post('/', async (c) => {
  const db = new Database(c.env.DB as unknown as D1Database)
  const groq = new GroqService(
    c.env.GROQ_API_KEY,
    c.env.GROQ_MODEL,
    parseFloat(c.env.LLM_TEMPERATURE),
    parseInt(c.env.LLM_MAX_TOKENS),
    parseInt(c.env.LLM_TIMEOUT_SECONDS)
  )

  try {
    const body = (await c.req.json()) as ChatRequest

    // Validate required fields
    if (!body.message || typeof body.message !== 'string') {
      return c.json({ error: 'Message is required' } as ErrorResponse, 400)
    }

    const conversationId = body.conversation_id ?? 1
    const userId = body.user_id ?? 1

    // Verify conversation exists for this user
    const conversation = await db.getConversation(conversationId, userId)
    if (!conversation) {
      return c.json({ error: 'Conversation not found for this user' } as ErrorResponse, 404)
    }
    if (conversation.is_closed) {
      return c.json({ error: 'Conversation is closed' } as ErrorResponse, 409)
    }

    // Save user message
    await db.createMessage(conversationId, 'user', body.message)

    // Generate LLM response
    const response = await groq.chat([
      { role: 'system', content: 'You are MindPal, a supportive mental health companion.' },
      { role: 'user', content: body.message },
    ])

    // Save assistant message
    const assistantMessage = await db.createMessage(conversationId, 'assistant', response)

    const chatResponse: ChatResponse = {
      response,
      conversation_id: conversationId,
      user_message_id: conversationId,
      assistant_message_id: assistantMessage.id,
      timestamp: assistantMessage.timestamp,
    }

    return c.json(chatResponse)
  } catch (error: any) {
    return c.json(
      { error: 'Internal server error', detail: error.message } as ErrorResponse,
      500
    )
  }
})

chatRouter.post('/stream', async (c) => {
  const db = new Database(c.env.DB as unknown as D1Database)
  const groq = new GroqService(
    c.env.GROQ_API_KEY,
    c.env.GROQ_MODEL,
    parseFloat(c.env.LLM_TEMPERATURE),
    parseInt(c.env.LLM_MAX_TOKENS),
    parseInt(c.env.LLM_TIMEOUT_SECONDS)
  )

  try {
    const body = (await c.req.json()) as ChatRequest

    if (!body.message || typeof body.message !== 'string') {
      return c.json({ error: 'Message is required' } as ErrorResponse, 400)
    }

    const conversationId = body.conversation_id ?? 1
    const userId = body.user_id ?? 1

    const conversation = await db.getConversation(conversationId, userId)
    if (!conversation) {
      return c.json({ error: 'Conversation not found for this user' } as ErrorResponse, 404)
    }
    if (conversation.is_closed) {
      return c.json({ error: 'Conversation is closed' } as ErrorResponse, 409)
    }

    await db.createMessage(conversationId, 'user', body.message)

    const stream = new ReadableStream({
      async start(controller) {
        const encoder = new TextEncoder()
        const send = (data: string) => controller.enqueue(encoder.encode(data))

        try {
          // Send message_start event
          send(`event: message_start\ndata: ${JSON.stringify({ conversation_id: conversationId, user_message_id: conversationId })}\n\n`)

          // For now, generate full response and stream it token-like
          const response = await groq.chat([
            { role: 'system', content: 'You are MindPal, a supportive mental health companion.' },
            { role: 'user', content: body.message },
          ])

          // Stream response in chunks
          const chunkSize = 5
          for (let i = 0; i < response.length; i += chunkSize) {
            const chunk = response.slice(i, i + chunkSize)
            send(`event: token\ndata: ${JSON.stringify({ token: chunk })}\n\n`)
            // Small delay for realistic streaming
            await new Promise((resolve) => setTimeout(resolve, 20))
          }

          const assistantMessage = await db.createMessage(conversationId, 'assistant', response)

          send(
            `event: message_end\ndata: ${JSON.stringify({
              conversation_id: conversationId,
              assistant_message_id: assistantMessage.id,
              response,
              timestamp: assistantMessage.timestamp,
            })}\n\n`
          )

          controller.close()
        } catch (error: any) {
          send(
            `event: error\ndata: ${JSON.stringify({
              message: 'Streaming failed before completion.',
              error_code: 'stream_internal_error',
              retryable: true,
              partial_saved: false,
            })}\n\n`
          )
          controller.close()
        }
      },
    })

    return new Response(stream, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'X-Accel-Buffering': 'no',
        'Access-Control-Allow-Origin': 'https://mindpal-frontend.ibrahimadelabdelaziz.workers.dev',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    })
  } catch (error: any) {
    return c.json(
      { error: 'Internal server error', detail: error.message } as ErrorResponse,
      500
    )
  }
})

export default chatRouter
