import { useEffect, useState } from 'react'

import { getApiBaseUrl } from '../lib/api'

export type ApiHealthState = 'checking' | 'ok' | 'degraded' | 'down'

export interface ApiHealthInfo {
  state: ApiHealthState
  demoMode: boolean
  standaloneMode: boolean
}

interface HealthPayload {
  status?: string
  demo_mode?: boolean
  standalone_mode?: boolean
  checks?: {
    database?: string
    redis?: string
  }
}

const DEFAULT_INFO: ApiHealthInfo = {
  state: 'checking',
  demoMode: false,
  standaloneMode: false,
}

export function useApiHealth(): ApiHealthInfo {
  const [info, setInfo] = useState<ApiHealthInfo>(DEFAULT_INFO)

  useEffect(() => {
    let cancelled = false

    async function check() {
      try {
        const response = await fetch(`${getApiBaseUrl()}/health`)
        if (!response.ok) {
          if (!cancelled) setInfo({ state: 'down', demoMode: false, standaloneMode: false })
          return
        }
        const payload = (await response.json()) as HealthPayload
        if (cancelled) return

        let state: ApiHealthState = 'ok'
        if (payload.status !== 'ok') {
          state =
            payload.checks?.database === 'error' || payload.checks?.redis === 'error'
              ? 'down'
              : 'degraded'
        }

        setInfo({
          state,
          demoMode: payload.demo_mode === true,
          standaloneMode: payload.standalone_mode === true,
        })
      } catch {
        if (!cancelled) {
          setInfo({ state: 'down', demoMode: false, standaloneMode: false })
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

  return info
}
