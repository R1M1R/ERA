/** Parse FastAPI-style error payloads into user-facing messages. */
export async function parseApiError(response: Response): Promise<string> {
  const text = await response.text()
  if (!text) {
    return `Request failed with status ${response.status}`
  }

  try {
    const payload = JSON.parse(text) as { detail?: unknown }
    const { detail } = payload
    if (typeof detail === 'string') {
      return detail
    }
    if (Array.isArray(detail)) {
      return detail
        .map((item) => {
          if (typeof item === 'object' && item && 'msg' in item) {
            return String((item as { msg: string }).msg)
          }
          return String(item)
        })
        .join(', ')
    }
  } catch {
    // Fall through to raw text.
  }

  return text
}
