import { useEffect, useRef, useState } from 'react'

import { fetchTaskStatus } from '../lib/api'
import type { TaskStatusResponse } from '../types/api'

const DEFAULT_INTERVAL_MS = 1500

interface UseTaskPollingOptions {
  intervalMs?: number
  onCompleted?: () => void
}

interface UseTaskPollingResult {
  status: TaskStatusResponse | null
  error: string | null
  isPolling: boolean
}

export function useTaskPolling(
  taskId: string | null,
  options: UseTaskPollingOptions = {},
): UseTaskPollingResult {
  const { intervalMs = DEFAULT_INTERVAL_MS, onCompleted } = options
  const [status, setStatus] = useState<TaskStatusResponse | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [isPolling, setIsPolling] = useState(false)
  const completedTaskIdRef = useRef<string | null>(null)

  useEffect(() => {
    if (!taskId) {
      setStatus(null)
      setError(null)
      setIsPolling(false)
      completedTaskIdRef.current = null
      return
    }

    let cancelled = false
    let timeoutId: number | undefined

    const poll = async () => {
      setIsPolling(true)

      try {
        const nextStatus = await fetchTaskStatus(taskId)
        if (cancelled) {
          return
        }

        setStatus(nextStatus)
        setError(null)

        if (nextStatus.status === 'queued' || nextStatus.status === 'running') {
          timeoutId = window.setTimeout(poll, intervalMs)
          return
        }

        setIsPolling(false)

        if (
          nextStatus.status === 'completed' &&
          completedTaskIdRef.current !== taskId
        ) {
          completedTaskIdRef.current = taskId
          onCompleted?.()
        }
      } catch (pollError) {
        if (cancelled) {
          return
        }

        const message = pollError instanceof Error ? pollError.message : 'Failed to fetch task status.'
        setError(message)
        setIsPolling(false)
      }
    }

    poll()

    return () => {
      cancelled = true
      if (timeoutId !== undefined) {
        window.clearTimeout(timeoutId)
      }
    }
  }, [taskId, intervalMs, onCompleted])

  return { status, error, isPolling }
}
