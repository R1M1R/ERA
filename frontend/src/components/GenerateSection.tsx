import { useEffect } from 'react'

import { useI18n } from '../hooks/useI18n'

interface GenerateSectionProps {
  isSubmitting: boolean
  isApiReady: boolean
  error: string | null
  onSubmit: () => Promise<void>
}

export function GenerateSection({ isSubmitting, isApiReady, error, onSubmit }: GenerateSectionProps) {
  const { t } = useI18n()

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key.toLowerCase() === 'g' && !event.metaKey && !event.ctrlKey && !event.altKey) {
        const target = event.target as HTMLElement
        if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') {
          return
        }
        if (isApiReady && !isSubmitting) {
          void onSubmit()
        }
      }
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [isApiReady, isSubmitting, onSubmit])

  return (
    <section className="panel animate-fade-in-up" id="generate-section">
      <div className="mb-5 flex items-start justify-between gap-4">
        <div>
          <h2 className="font-display text-2xl text-parchment-50">{t('generateTitle')}</h2>
          <p className="mt-1 text-sm text-parchment-200/70">{t('generateDesc')}</p>
        </div>
        <span className="rounded-full border border-parchment-500/30 bg-parchment-500/10 px-3 py-1 text-xs font-medium text-parchment-300">
          POST /generate
        </span>
      </div>

      {isApiReady ? (
        <p className="mb-4 rounded-xl border border-emerald-500/30 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-200">
          <span className="font-semibold">{t('generateReady')}</span>{' '}
          <kbd className="rounded border border-emerald-500/40 bg-emerald-500/20 px-1.5 py-0.5 font-mono text-xs">
            G
          </kbd>
        </p>
      ) : (
        <p className="mb-4 rounded-xl border border-amber-500/30 bg-amber-500/10 px-4 py-3 text-sm text-amber-200">
          {t('generateOffline')}
        </p>
      )}

      {error ? (
        <p className="mb-4 rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
          {error}
        </p>
      ) : null}

      <button
        type="button"
        className="btn-primary btn-glow min-w-[12rem]"
        disabled={isSubmitting || !isApiReady}
        onClick={() => void onSubmit()}
      >
        {isSubmitting ? (
          <span className="flex items-center gap-2">
            <span className="h-4 w-4 animate-spin rounded-full border-2 border-archive-950/30 border-t-archive-950" />
            {t('generateQueueing')}
          </span>
        ) : (
          t('generateBtn')
        )}
      </button>
    </section>
  )
}
