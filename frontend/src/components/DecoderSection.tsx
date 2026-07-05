import { useCallback, useState, type DragEvent } from 'react'

import { useI18n } from '../hooks/useI18n'
import { useTypewriter } from '../hooks/useTypewriter'
import type { TranslationKey } from '../lib/i18n'
import type { VerifyResponse } from '../types/api'

const VERIFY_MESSAGE_KEYS = new Set<TranslationKey>([
  'verify_authentic',
  'verify_fake_corrupted',
  'verify_fake_hash_mismatch',
  'verify_fake_not_in_archive',
])

function resolveVerifyMessage(
  verification: VerifyResponse,
  t: (key: TranslationKey) => string,
): string {
  const key = verification.message_key
  if (key && VERIFY_MESSAGE_KEYS.has(key as TranslationKey)) {
    return t(key as TranslationKey)
  }
  return verification.detail ?? verification.message
}

interface DecoderSectionProps {
  previewUrl: string | null
  decodedText: string | null
  verification: VerifyResponse | null
  isVerifying: boolean
  error: string | null
  onFileSelect: (file: File | null) => void
  onVerify: () => Promise<void>
  onReset: () => void
}

function VerificationBadge({
  verification,
  verifiedLabel,
  fakeLabel,
  message,
}: {
  verification: VerifyResponse | null
  verifiedLabel: string
  fakeLabel: string
  message: string
}) {
  if (!verification) return null

  if (verification.verified) {
    return (
      <div className="flex animate-fade-in items-center gap-3 rounded-xl border border-emerald-500/40 bg-emerald-500/10 px-4 py-3">
        <span className="flex h-9 w-9 items-center justify-center rounded-full bg-emerald-500/20 text-lg text-emerald-300">
          ✓
        </span>
        <div>
          <p className="text-sm font-semibold text-emerald-200">{verifiedLabel}</p>
          <p className="text-xs text-emerald-300/80">{message}</p>
        </div>
      </div>
    )
  }

  return (
    <div className="flex animate-fade-in items-center gap-3 rounded-xl border border-red-500/40 bg-red-500/10 px-4 py-3">
      <span className="flex h-9 w-9 items-center justify-center rounded-full bg-red-500/20 text-lg text-red-300">
        ✕
      </span>
      <div>
        <p className="text-sm font-semibold text-red-200">{fakeLabel}</p>
        <p className="text-xs text-red-300/80">{message}</p>
      </div>
    </div>
  )
}

export function DecoderSection({
  previewUrl,
  decodedText,
  verification,
  isVerifying,
  error,
  onFileSelect,
  onVerify,
  onReset,
}: DecoderSectionProps) {
  const { t } = useI18n()
  const [isDragging, setIsDragging] = useState(false)
  const { displayedText, isComplete } = useTypewriter(decodedText ?? '', {
    enabled: Boolean(decodedText && verification?.verified),
    speedMs: 18,
  })

  const handleDrop = useCallback(
    (event: DragEvent) => {
      event.preventDefault()
      setIsDragging(false)
      const file = event.dataTransfer.files[0]
      if (file) onFileSelect(file)
    },
    [onFileSelect],
  )

  const copyChronicle = useCallback(async () => {
    if (!decodedText) return
    try {
      await navigator.clipboard.writeText(decodedText)
    } catch {
      // clipboard may be unavailable
    }
  }, [decodedText])

  return (
    <section className="panel" id="decoder-section">
      <div className="mb-5 flex items-start justify-between gap-4">
        <div>
          <h2 className="font-display text-2xl text-parchment-50">{t('decoderTitle')}</h2>
          <p className="mt-1 text-sm text-parchment-200/70">{t('decoderDesc')}</p>
        </div>
        <span className="rounded-full border border-archive-600 bg-archive-800 px-3 py-1 text-xs font-medium text-parchment-300">
          POST /verify
        </span>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <div>
          <label
            className={`flex cursor-pointer flex-col items-center justify-center rounded-xl border border-dashed px-6 py-10 text-center transition ${
              isDragging
                ? 'border-parchment-400 bg-parchment-500/10'
                : 'border-archive-600 bg-archive-950/40 hover:border-parchment-500/40 hover:bg-archive-900/60'
            }`}
            onDragEnter={() => setIsDragging(true)}
            onDragLeave={() => setIsDragging(false)}
            onDragOver={(event) => event.preventDefault()}
            onDrop={handleDrop}
          >
            <input
              type="file"
              accept="image/png,image/jpeg,image/webp"
              className="hidden"
              onChange={(event) => onFileSelect(event.target.files?.[0] ?? null)}
            />
            <span className="text-3xl text-parchment-500">⬆</span>
            <span className="mt-2 text-sm font-medium text-parchment-100">
              {isDragging ? t('dropRelease') : t('dropBrowse')}
            </span>
            <span className="mt-2 text-xs text-archive-600">{t('dropHint')}</span>
          </label>

          {previewUrl ? (
            <div className="relative mt-4 overflow-hidden rounded-xl border border-archive-700 bg-archive-950">
              <img src={previewUrl} alt="Uploaded artifact preview" className="max-h-72 w-full object-contain" />
              {isVerifying ? (
                <div className="pointer-events-none absolute inset-0 overflow-hidden">
                  <div className="absolute inset-x-0 top-0 h-1/3 animate-scan bg-gradient-to-b from-parchment-500/25 to-transparent" />
                </div>
              ) : null}
            </div>
          ) : null}

          <div className="mt-4 flex flex-wrap gap-3">
            <button
              type="button"
              className="btn-primary"
              disabled={!previewUrl || isVerifying}
              onClick={() => void onVerify()}
            >
              {isVerifying ? (
                <span className="flex items-center gap-2">
                  <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-archive-950/30 border-t-archive-950" />
                  {t('verifying')}
                </span>
              ) : (
                t('verifyAgain')
              )}
            </button>
            <button type="button" className="btn-secondary" onClick={onReset}>
              {t('reset')}
            </button>
          </div>

          <div className="mt-4 space-y-3">
            <VerificationBadge
              verification={verification}
              verifiedLabel={t('verifiedServer')}
              fakeLabel={t('fakeCorrupted')}
              message={verification ? resolveVerifyMessage(verification, t) : ''}
            />
            {error && !verification?.verified ? (
              <p className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
                {error}
              </p>
            ) : null}
          </div>
        </div>

        <div className="rounded-xl border border-archive-700 bg-[#120f0d] p-5 shadow-inner">
          <div className="mb-4 flex items-center justify-between gap-2">
            <p className="text-xs font-semibold uppercase tracking-[0.25em] text-parchment-500">
              {t('recoveredChronicle')}
            </p>
            <div className="flex items-center gap-2">
              {decodedText && verification?.verified && isComplete ? (
                <button type="button" className="btn-secondary px-3 py-1 text-xs" onClick={() => void copyChronicle()}>
                  {t('copy')}
                </button>
              ) : null}
              {decodedText && verification?.verified ? (
                <span className="font-mono text-xs text-emerald-400">
                  {isComplete ? t('complete') : t('receiving')}
                </span>
              ) : null}
            </div>
          </div>

          <div
            className={`min-h-64 rounded-lg border p-4 font-mono text-sm leading-relaxed ${
              verification?.verified
                ? 'border-emerald-500/20 bg-black/40 text-emerald-300'
                : 'border-archive-800 bg-black/40 text-archive-600'
            }`}
          >
            {decodedText && verification?.verified ? (
              <>
                {displayedText}
                {!isComplete ? (
                  <span className="ml-0.5 inline-block h-4 w-2 animate-pulse bg-emerald-400" />
                ) : null}
              </>
            ) : isVerifying ? (
              <span className="animate-pulse-slow">{t('verifyingServer')}</span>
            ) : verification && !verification.verified ? (
              t('authFailed')
            ) : (
              t('awaitingUpload')
            )}
          </div>
        </div>
      </div>
    </section>
  )
}
