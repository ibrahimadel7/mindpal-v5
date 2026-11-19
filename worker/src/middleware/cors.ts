import { Context, type Next } from 'hono'

export function corsMiddleware(allowedOrigin: string) {
  return async (c: Context, next: Next) => {
    const origin = c.req.header('Origin')

    if (origin === allowedOrigin) {
      c.header('Access-Control-Allow-Origin', allowedOrigin)
    }

    c.header('Vary', 'Origin')

    // Handle preflight requests
    if (c.req.method === 'OPTIONS') {
      c.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      c.header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
      c.header('Access-Control-Max-Age', '86400')
      return c.body(null, 204)
    }

    await next()
  }
}
