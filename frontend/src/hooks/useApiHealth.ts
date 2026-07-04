import { useEffect, useState } from 'react'

import { getApiBaseUrl } from '../lib/api'

export type ApiHealthState = 'checking' | 'ok' | 'down'

export function useApiHealth(): ApiHealthState {
  const [state, setState] = useState<ApiHealthState>('checking')

  useEffect(() => {
    let cancelled = false

    async function check() {
      try {
        const response = await fetch(`${getApiBaseUrl()}/health`)
        if (!cancelled) {
          setState(response.ok ? 'ok' : 'down')
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
