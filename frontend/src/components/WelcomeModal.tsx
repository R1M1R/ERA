import { useCallback, useEffect, useRef, useState } from 'react'

import { useI18n } from '../hooks/useI18n'

const STORAGE_KEY = 'era-welcome-seen'

export function WelcomeModal() {
  const { t } = useI18n()
  const [open, setOpen] = useState(false)
  const buttonRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    try {
      if (!localStorage.getItem(STORAGE_KEY)) {
        setOpen(true)
      }
    } catch {
      setOpen(true)
    }
  }, [])

  const dismiss = useCallback(() => {
    setOpen(false)
    try {
      localStorage.setItem(STORAGE_KEY, '1')
    } catch {
      // ignore
    }
  }, [])

  useEffect(() => {
    if (!open) return

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') dismiss()
    }

    document.addEventListener('keydown', onKeyDown)
    document.body.style.overflow = 'hidden'
    buttonRef.current?.focus()

    return () => {
      document.removeEventListener('keydown', onKeyDown)
      document.body.style.overflow = ''
    }
  }, [open, dismiss])

  if (!open) return null

  return (
    <div
      className="fixed inset-0 z-[60] flex animate-fade-in items-center justify-center bg-black/70 p-4 backdrop-blur-sm"
      role="dialog"
      aria-modal="true"
      aria-label={t('welcomeTitle')}
      onClick={dismiss}
    >
      <div
        className="animate-scale-in panel max-w-lg border-parchment-500/30 shadow-glow"
        onClick={(event) => event.stopPropagation()}
      >
        <p className="mb-1 text-xs font-semibold uppercase tracking-[0.3em] text-parchment-500">
          {t('archive')}
        </p>
        <h2 className="font-display text-2xl text-parchment-50">{t('welcomeTitle')}</h2>
        <p className="mt-3 text-sm leading-relaxed text-parchment-200/80">{t('welcomeDesc')}</p>

        <ol className="mt-5 space-y-3 text-sm text-parchment-200">
          <li className="flex gap-3">
            <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-parchment-500/20 text-xs font-bold text-parchment-300">
              1
            </span>
            <span>{t('welcomeStep1')}</span>
          </li>
          <li className="flex gap-3">
            <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-parchment-500/20 text-xs font-bold text-parchment-300">
              2
            </span>
            <span>{t('welcomeStep2')}</span>
          </li>
          <li className="flex gap-3">
            <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-parchment-500/20 text-xs font-bold text-parchment-300">
              3
            </span>
            <span>{t('welcomeStep3')}</span>
          </li>
        </ol>

        <p className="mt-4 text-xs text-archive-600">
          <kbd className="rounded border border-archive-600 bg-archive-800 px-1.5 py-0.5 font-mono">G</kbd>{' '}
          — {t('welcomeShortcut')}
        </p>

        <button ref={buttonRef} type="button" className="btn-primary btn-glow mt-6 w-full" onClick={dismiss}>
          {t('welcomeStart')}
        </button>
      </div>
    </div>
  )
}
