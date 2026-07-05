import { useCallback, useEffect, useRef, useState } from 'react'

import { verifyArtifact } from '../lib/api'
import { useI18n } from './useI18n'
import type { VerifyResponse } from '../types/api'

interface UseDecoderResult {
  file: File | null
  previewUrl: string | null
  decodedText: string | null
  verification: VerifyResponse | null
  isVerifying: boolean
  error: string | null
  selectFile: (file: File | null) => void
  verify: () => Promise<void>
  reset: () => void
}

export function useDecoder(): UseDecoderResult {
  const { t } = useI18n()
  const [file, setFile] = useState<File | null>(null)
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [decodedText, setDecodedText] = useState<string | null>(null)
  const [verification, setVerification] = useState<VerifyResponse | null>(null)
  const [isVerifying, setIsVerifying] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const latestFileRef = useRef<File | null>(null)

  const reset = useCallback(() => {
    setPreviewUrl((currentUrl) => {
      if (currentUrl) {
        URL.revokeObjectURL(currentUrl)
      }
      return null
    })
    setFile(null)
    latestFileRef.current = null
    setDecodedText(null)
    setVerification(null)
    setError(null)
    setIsVerifying(false)
  }, [])

  const selectFile = useCallback((nextFile: File | null) => {
    reset()
    if (!nextFile) {
      return
    }

    latestFileRef.current = nextFile
    setFile(nextFile)
    setPreviewUrl(URL.createObjectURL(nextFile))
  }, [reset])

  const verify = useCallback(async () => {
    const targetFile = latestFileRef.current
    if (!targetFile) {
      setError(t('decoderUploadRequired'))
      return
    }

    setIsVerifying(true)
    setError(null)
    setVerification(null)
    setDecodedText(null)

    try {
      const result = await verifyArtifact(targetFile)
      setVerification(result)

      if (result.verified && result.text) {
        setDecodedText(result.text)
        setError(null)
      } else {
        setDecodedText(result.text ?? null)
        setError(t('fakeCorrupted'))
      }
    } catch (verifyError) {
      const message = verifyError instanceof Error ? verifyError.message : t('decoderVerifyFailed')
      setVerification(null)
      setDecodedText(null)
      setError(message)
    } finally {
      setIsVerifying(false)
    }
  }, [t])

  useEffect(() => {
    if (!file) {
      return
    }

    void verify()
  }, [file, verify])

  return {
    file,
    previewUrl,
    decodedText,
    verification,
    isVerifying,
    error,
    selectFile,
    verify,
    reset,
  }
}
