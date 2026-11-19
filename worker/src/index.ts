import { Hono } from 'hono'
import chatRouter from './routes/chat.ts'
import conversationsRouter from './routes/conversations.ts'
import insightsRouter from './routes/insights.ts'
import recommendationsRouter from './routes/recommendations.ts'
import { corsMiddleware } from './middleware/cors'
import { securityHeadersMiddleware } from './middleware/security-headers'
import { rateLimitMiddleware } from './middleware/rate-limit'
import type { Env } from './types'

const app = new Hono<{ Bindings: Env }>()

// Security headers
app.use('*', securityHeadersMiddleware)

// Rate limiting
app.use('*', rateLimitMiddleware)

// CORS - restrict to your frontend domain
const ALLOWED_ORIGIN = 'https://mindpal-frontend.ibrahimadelabdelaziz.workers.dev'
app.use('*', corsMiddleware(ALLOWED_ORIGIN))

// Health check
app.get('/health', (c) => c.json({ status: 'ok' }))

// API routes
app.route('/chat', chatRouter)
app.route('/conversations', conversationsRouter)
app.route('/insights', insightsRouter)
app.route('/recommendations', recommendationsRouter)

// 404 handler
app.notFound((c) => c.json({ error: 'Not found' }, 404))

// Error handler
app.onError((err, c) => {
  return c.json({ error: 'Internal server error', detail: err.message }, 500)
})

export default app
