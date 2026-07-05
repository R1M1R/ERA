import { useEffect, useState } from 'react'

import { getApiBaseUrl } from '../lib/api'
import type { HealthResponse } from '../types/api'

export type ApiHealthState = 'checking' | 'ok' | 'degraded' | 'down'

export interface ApiHealthInfo {
  state: ApiHealthState
  demoMode: boolean
  standaloneMode: boolean
  billingConfigured: boolean
  databasePersistent: boolean
  openaiForPro: boolean
  productionReady: boolean
}

const DEFAULT_INFO: ApiHealthInfo = {
  state: 'checking',
  demoMode: false,
  standaloneMode: false,
  billingConfigured: false,
  databasePersistent: false,
  openaiForPro: false,
  productionReady: false,
}

function mapHealthState(payload: HealthResponse): ApiHealthState {
  if (payload.status === 'ok') return 'ok'
  if (payload.checks?.database === 'error' || payload.checks?.redis === 'error') {
    return 'down'
  }
  return 'degraded'
}

export function useApiHealth(): ApiHealthInfo {
  const [info, setInfo] = useState<ApiHealthInfo>(DEFAULT_INFO)

  useEffect(() => {
    let cancelled = false

    async function check() {
      try {
        const response = await fetch(`${getApiBaseUrl()}/health`, {
          signal: AbortSignal.timeout(15_000),
        })
        if (!response.ok) {
          if (!cancelled) setInfo({ ...DEFAULT_INFO, state: 'down' })
          return
        }
        const payload = (await response.json()) as HealthResponse
        if (cancelled) return

        setInfo({
          state: mapHealthState(payload),
          demoMode: payload.demo_mode === true,
          standaloneMode: payload.standalone_mode === true,
          billingConfigured: payload.billing_configured === true,
          databasePersistent: payload.database_persistent === true,
          openaiForPro: payload.openai_for_pro === true,
          productionReady: payload.production_ready === true,
        })
      } catch {
        if (!cancelled) {
          setInfo({ ...DEFAULT_INFO, state: 'down' })
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
