import { useCallback, useEffect, useState } from 'react'

import { fetchProStatus } from '../lib/api'
import { clearProKey, getProKey } from '../lib/proKey'
import type { ProStatusResponse } from '../types/api'

export interface ProInfo {
  loading: boolean
  active: boolean
  email: string | null
  openaiForPro: boolean
  statusError: boolean
  status: ProStatusResponse | null
  refresh: () => Promise<void>
  disconnect: () => void
}

export function useProStatus(): ProInfo {
  const [loading, setLoading] = useState(true)
  const [status, setStatus] = useState<ProStatusResponse | null>(null)
  const [statusError, setStatusError] = useState(false)

  const refresh = useCallback(async () => {
    if (!getProKey()) {
      setStatus(null)
      setStatusError(false)
      setLoading(false)
      return
    }

    setLoading(true)
    try {
      const payload = await fetchProStatus()
      setStatus(payload)
      setStatusError(false)
    } catch {
      setStatus(null)
      setStatusError(true)
    } finally {
      setLoading(false)
    }
  }, [])

  const disconnect = useCallback(() => {
    clearProKey()
    setStatus(null)
    setStatusError(false)
    setLoading(false)
  }, [])

  useEffect(() => {
    void refresh()
  }, [refresh])

  return {
    loading,
    active: status?.active === true,
    email: status?.email ?? null,
    openaiForPro: status?.openai_for_pro === true,
    statusError,
    status,
    refresh,
    disconnect,
  }
}
