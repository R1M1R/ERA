import { useEffect } from 'react'

interface ImageLightboxProps {
  src: string
  alt: string
  hash: string
  createdAt: string
  onClose: () => void
  onVerify?: () => void
}

export function ImageLightbox({ src, alt, hash, createdAt, onClose, onVerify }: ImageLightboxProps) {
  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        onClose()
      }
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
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4 backdrop-blur-sm animate-fade-in"
      role="dialog"
      aria-modal="true"
      aria-label="Artifact preview"
      onClick={onClose}
    >
      <div
        className="animate-scale-in relative max-h-[90vh] w-full max-w-3xl overflow-hidden rounded-2xl border border-archive-600 bg-archive-900 shadow-glow"
        onClick={(event) => event.stopPropagation()}
      >
        <img src={src} alt={alt} className="max-h-[70vh] w-full object-contain bg-black/40" />
        <div className="flex flex-wrap items-center justify-between gap-3 border-t border-archive-700 p-4">
          <div>
            <p className="font-mono text-xs text-parchment-500">#{hash.slice(0, 12)}</p>
            <p className="text-sm text-parchment-300">{createdAt}</p>
          </div>
          <div className="flex gap-2">
            <a href={src} download={`era-${hash}.png`} className="btn-secondary">
              Download
            </a>
            {onVerify ? (
              <button type="button" className="btn-primary" onClick={onVerify}>
                Verify
              </button>
            ) : null}
            <button type="button" className="btn-secondary" onClick={onClose}>
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
