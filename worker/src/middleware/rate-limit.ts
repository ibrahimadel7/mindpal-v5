import { Context, type Next } from 'hono'

// Simple in-memory rate limiter (per IP, per route)
// For production, consider using Cloudflare KV or a dedicated rate-limiting service
const rateLimitMap = new Map<string, { count: number; resetTime: number }>()

const WINDOW_MS = 60 * 1000 // 1 minute
const MAX_REQUESTS = 60 // 60 requests per minute per IP

export function rateLimitMiddleware(c: Context, next: Next) {
  const ip = c.req.header('CF-Connecting-IP') || 'unknown'
  const now = Date.now()
  const key = ip

  let record = rateLimitMap.get(key)

  if (!record || now > record.resetTime) {
    record = { count: 1, resetTime: now + WINDOW_MS }
    rateLimitMap.set(key, record)
  } else {
    record.count++
    if (record.count > MAX_REQUESTS) {
      return c.json({ error: 'Too many requests' }, 429)
    }
  }

  c.header('X-RateLimit-Limit', String(MAX_REQUESTS))
  c.header('X-RateLimit-Remaining', String(Math.max(0, MAX_REQUESTS - record.count)))
  c.header('X-RateLimit-Reset', String(Math.ceil(record.resetTime / 1000)))

  return next()
}
