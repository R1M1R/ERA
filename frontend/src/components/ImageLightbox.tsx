import { useEffect } from 'react'

import { useI18n } from '../hooks/useI18n'

interface ImageLightboxProps {
  src: string
  alt: string
  hash: string
  createdAt: string
  onClose: () => void
  onVerify?: () => void
}

export function ImageLightbox({ src, alt, hash, createdAt, onClose, onVerify }: ImageLightboxProps) {
  const { t } = useI18n()

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    document.addEventListener('keydown', onKeyDown)
    document.body.style.overflow = 'hidden'
    return () => {
      document.removeEventListener('keydown', onKeyDown)
      document.body.style.overflow = ''
    }
  }, [onClose])

  return (
    <div
      className="fixed inset-0 z-50 flex animate-fade-in items-center justify-center bg-black/80 p-4 backdrop-blur-sm"
      role="dialog"
      aria-modal="true"
      aria-label="Artifact preview"
      onClick={onClose}
    >
      <div
        className="animate-scale-in relative max-h-[90vh] w-full max-w-3xl overflow-hidden rounded-2xl border border-archive-600 bg-archive-900 shadow-glow"
        onClick={(event) => event.stopPropagation()}
      >
        <img src={src} alt={alt} className="max-h-[70vh] w-full bg-black/40 object-contain" />
        <div className="flex flex-wrap items-center justify-between gap-3 border-t border-archive-700 p-4">
          <div>
            <p className="font-mono text-xs text-parchment-500">#{hash.slice(0, 12)}</p>
            <p className="text-sm text-parchment-300">{createdAt}</p>
          </div>
          <div className="flex gap-2">
            <a href={src} download={`era-${hash}.png`} className="btn-secondary">
              {t('download')}
            </a>
            {onVerify ? (
              <button type="button" className="btn-primary" onClick={onVerify}>
                {t('verify')}
              </button>
            ) : null}
            <button type="button" className="btn-secondary" onClick={onClose}>
              {t('lightboxClose')}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
