import { useEffect, useState } from 'react'

import { useI18n } from '../hooks/useI18n'

export function KeyboardHelp() {
  const { t } = useI18n()
  const [open, setOpen] = useState(false)

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === '?' && !event.metaKey && !event.ctrlKey) {
        const target = event.target as HTMLElement
        if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') return
        event.preventDefault()
        setOpen((v) => !v)
      }
      if (event.key === 'Escape') setOpen(false)
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [])

  if (!open) {
    return (
      <button
        type="button"
        className="fixed bottom-20 right-4 z-30 hidden h-10 w-10 items-center justify-center rounded-full border border-archive-600 bg-archive-900/90 text-sm font-bold text-parchment-400 shadow-glow backdrop-blur transition hover:border-parchment-500/40 hover:text-parchment-100 sm:bottom-6 sm:flex"
        onClick={() => setOpen(true)}
        aria-label={t('helpTitle')}
      >
        ?
      </button>
    )
  }

  return (
    <div
      className="fixed inset-0 z-[55] flex animate-fade-in items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
      onClick={() => setOpen(false)}
    >
      <div className="panel animate-scale-in max-w-sm" onClick={(e) => e.stopPropagation()}>
        <h3 className="font-display text-xl text-parchment-50">{t('helpTitle')}</h3>
        <ul className="mt-4 space-y-3 text-sm text-parchment-300">
          <li className="flex justify-between gap-4">
            <span>{t('helpGenerate')}</span>
            <kbd className="rounded border border-archive-600 bg-archive-800 px-2 py-0.5 font-mono text-xs">G</kbd>
          </li>
          <li className="flex justify-between gap-4">
            <span>{t('helpShortcuts')}</span>
            <kbd className="rounded border border-archive-600 bg-archive-800 px-2 py-0.5 font-mono text-xs">?</kbd>
          </li>
          <li className="flex justify-between gap-4">
            <span>{t('helpClose')}</span>
            <kbd className="rounded border border-archive-600 bg-archive-800 px-2 py-0.5 font-mono text-xs">Esc</kbd>
          </li>
        </ul>
        <button type="button" className="btn-secondary mt-5 w-full" onClick={() => setOpen(false)}>
          {t('lightboxClose')}
        </button>
      </div>
    </div>
  )
}
