import { Hono } from 'hono'

const recommendationsRouter = new Hono()

recommendationsRouter.get('/today', async (c) => {
  return c.json({ items: [] })
})

recommendationsRouter.post('/generate', async (c) => {
  return c.json({ items: [] })
})

recommendationsRouter.get('/history', async (c) => {
  return c.json({ items: [] })
})

export default recommendationsRouter
