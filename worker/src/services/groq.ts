export class GroqService {
  constructor(
    private apiKey: string,
    private model: string,
    private temperature: number,
    private maxTokens: number,
    private timeoutSeconds: number
  ) {}

  async chat(messages: { role: string; content: string }[]): Promise<string> {
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), this.timeoutSeconds * 1000)

    try {
      const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: this.model,
          messages,
          temperature: this.temperature,
          max_tokens: this.maxTokens,
        }),
        signal: controller.signal,
      })

      if (!response.ok) {
        const errorText = await response.text()
        throw new Error(`Groq API error: ${response.status} ${errorText}`)
      }

      const data = await response.json()
      return data.choices?.[0]?.message?.content ?? ''
    } finally {
      clearTimeout(timeoutId)
    }
  }
}
