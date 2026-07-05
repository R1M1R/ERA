import { useCallback, useState } from 'react'

import { submitGeneration } from '../lib/api'
import { useI18n } from './useI18n'
import type { TaskStatusResponse } from '../types/api'
import { useTaskPolling } from './useTaskPolling'

interface UseGenerationResult {
  taskId: string | null
  status: TaskStatusResponse | null
  isSubmitting: boolean
  isPolling: boolean
  error: string | null
  submit: () => Promise<void>
  reset: () => void
}

export function useGeneration(onCompleted?: () => void): UseGenerationResult {
  const { t } = useI18n()
  const [taskId, setTaskId] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const { status, error: pollingError, isPolling } = useTaskPolling(taskId, {
    onCompleted,
  })

  const submit = useCallback(async () => {
    setIsSubmitting(true)
    setError(null)

    try {
      const response = await submitGeneration()
      setTaskId(response.task_id)
    } catch (submitError) {
      const message = submitError instanceof Error ? submitError.message : t('generationQueueFailed')
      setError(message)
    } finally {
      setIsSubmitting(false)
    }
  }, [t])

  const reset = useCallback(() => {
    setTaskId(null)
    setError(null)
  }, [])

  return {
    taskId,
    status,
    isSubmitting,
    isPolling,
    error: error ?? pollingError,
    submit,
    reset,
  }
}
