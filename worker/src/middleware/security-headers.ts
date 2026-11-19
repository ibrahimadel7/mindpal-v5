import { Context, type Next } from 'hono'

export function securityHeadersMiddleware(c: Context, next: Next) {
  c.header('X-Content-Type-Options', 'nosniff')
  c.header('X-Frame-Options', 'DENY')
  c.header('Referrer-Policy', 'no-referrer')
  return next()
}
