import { useEffect, useState } from 'react'

import { getApiBaseUrl } from '../lib/api'

export type ApiHealthState = 'checking' | 'ok' | 'degraded' | 'down'

interface HealthPayload {
  status?: string
  checks?: {
    database?: string
    redis?: string
  }
}

export function useApiHealth(): ApiHealthState {
  const [state, setState] = useState<ApiHealthState>('checking')

  useEffect(() => {
    let cancelled = false

    async function check() {
      try {
        const response = await fetch(`${getApiBaseUrl()}/health`)
        if (!response.ok) {
          if (!cancelled) setState('down')
          return
        }
        const payload = (await response.json()) as HealthPayload
        if (cancelled) return
        if (payload.status === 'ok') {
          setState('ok')
        } else if (payload.checks?.database === 'error' || payload.checks?.redis === 'error') {
          setState('down')
        } else {
          setState('degraded')
        }
      } catch {
        if (!cancelled) {
          setState('down')
        }
      }
    }

    void check()
    const timer = window.setInterval(() => {
      void check()
    }, 30_000)

    return () => {
      cancelled = true
      window.clearInterval(timer)
    }
  }, [])

  return state
}
