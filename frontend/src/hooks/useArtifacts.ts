import { useCallback, useEffect, useState } from 'react'

import { fetchArtifacts } from '../lib/api'
import type { ArtifactItem } from '../types/api'

interface UseArtifactsOptions {
  pageSize?: number
  refreshKey?: number
}

interface UseArtifactsResult {
  items: ArtifactItem[]
  page: number
  pages: number
  total: number
  isLoading: boolean
  error: string | null
  setPage: (page: number) => void
  reload: () => void
}

export function useArtifacts(options: UseArtifactsOptions = {}): UseArtifactsResult {
  const { pageSize = 12, refreshKey = 0 } = options
  const [page, setPage] = useState(1)
  const [items, setItems] = useState<ArtifactItem[]>([])
  const [pages, setPages] = useState(0)
  const [total, setTotal] = useState(0)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [reloadToken, setReloadToken] = useState(0)

  const reload = useCallback(() => {
    setReloadToken((value) => value + 1)
  }, [])

  useEffect(() => {
    let cancelled = false

    const load = async () => {
      setIsLoading(true)
      setError(null)

      try {
        const response = await fetchArtifacts(page, pageSize)
        if (cancelled) {
          return
        }

        setItems(response.items)
        setPages(response.pages)
        setTotal(response.total)
      } catch (loadError) {
        if (!cancelled) {
          const message = loadError instanceof Error ? loadError.message : 'Failed to load artifacts.'
          setError(message)
        }
      } finally {
        if (!cancelled) {
          setIsLoading(false)
        }
      }
    }

    void load()

    return () => {
      cancelled = true
    }
  }, [page, pageSize, refreshKey, reloadToken])

  return {
    items,
    page,
    pages,
    total,
    isLoading,
    error,
    setPage,
    reload,
  }
}
