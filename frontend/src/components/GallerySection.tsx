import { useState } from 'react'

import { useI18n } from '../hooks/useI18n'
import { resolveArtifactImageUrl } from '../lib/api'
import type { ArtifactItem } from '../types/api'
import { ImageLightbox } from './ImageLightbox'

interface GallerySectionProps {
  items: ArtifactItem[]
  page: number
  pages: number
  total: number
  isLoading: boolean
  error: string | null
  onPageChange: (page: number) => void
  onReload: () => void
  onVerifyImage?: (imageUrl: string) => void
}

function formatCreatedAt(value: string, locale: string): string {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return value
  }
  return new Intl.DateTimeFormat(locale === 'ru' ? 'ru-RU' : undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date)
}

export function GallerySection({
  items,
  page,
  pages,
  total,
  isLoading,
  error,
  onPageChange,
  onReload,
  onVerifyImage,
}: GallerySectionProps) {
  const { t, locale } = useI18n()
  const [lightbox, setLightbox] = useState<ArtifactItem | null>(null)

  return (
    <section className="panel" id="gallery-section">
      <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
        <div>
          <h2 className="font-display text-2xl text-parchment-50">{t('galleryTitle')}</h2>
          <p className="mt-1 text-sm text-parchment-200/70">{t('galleryDesc')}</p>
        </div>
        <div className="flex items-center gap-3">
          <span className="rounded-full border border-archive-600 bg-archive-800 px-3 py-1 text-xs font-medium text-parchment-300">
            {total} {t('galleryCount')}
          </span>
          <button type="button" className="btn-secondary" onClick={onReload} disabled={isLoading}>
            {isLoading ? t('galleryLoading') : t('galleryRefresh')}
          </button>
        </div>
      </div>

      {error ? (
        <p className="mb-4 rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
          {error}
        </p>
      ) : null}

      {isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, index) => (
            <div
              key={index}
              className="aspect-[4/5] animate-pulse rounded-2xl border border-archive-700 bg-gradient-to-br from-archive-800/80 to-archive-900/40"
            />
          ))}
        </div>
      ) : items.length === 0 ? (
        <div className="rounded-xl border border-dashed border-archive-700 bg-archive-950/40 px-6 py-16 text-center">
          <p className="font-display text-xl text-parchment-400">{t('galleryEmpty')}</p>
          <p className="mt-2 text-sm text-archive-600">{t('galleryEmptyHint')}</p>
          <a href="#generate-section" className="btn-primary mt-6 inline-flex">
            {t('galleryGenerateNow')}
          </a>
        </div>
      ) : (
        <div className="columns-1 gap-4 sm:columns-2 xl:columns-3 [column-fill:_balance]">
          {items.map((artifact) => (
            <article
              key={artifact.id}
              className="group mb-4 break-inside-avoid overflow-hidden rounded-2xl border border-archive-700 bg-archive-950/50 shadow-glow transition duration-300 hover:-translate-y-0.5 hover:border-parchment-500/40"
            >
              <button
                type="button"
                className="relative block w-full overflow-hidden bg-black/30 text-left"
                onClick={() => setLightbox(artifact)}
              >
                <img
                  src={resolveArtifactImageUrl(artifact.image_url)}
                  alt={`Artifact ${artifact.public_hash.slice(0, 8)}`}
                  className="w-full object-cover transition duration-500 group-hover:scale-[1.03] [image-rendering:pixelated]"
                  loading="lazy"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-archive-950/80 via-transparent to-transparent opacity-0 transition group-hover:opacity-100" />
                <div className="absolute left-3 top-3">
                  <span
                    className={`rounded-full px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.18em] backdrop-blur-sm ${
                      artifact.is_solved
                        ? 'bg-emerald-500/25 text-emerald-200'
                        : 'bg-parchment-500/20 text-parchment-200'
                    }`}
                  >
                    {artifact.is_solved ? t('solved') : t('unsolved')}
                  </span>
                </div>
                <span className="absolute bottom-3 left-3 rounded bg-black/50 px-2 py-1 text-[10px] text-parchment-300 opacity-0 backdrop-blur transition group-hover:opacity-100">
                  {t('clickExpand')}
                </span>
              </button>

              <div className="space-y-2 p-4">
                <p className="font-mono text-xs text-parchment-500">#{artifact.public_hash.slice(0, 12)}</p>
                <p className="text-sm text-parchment-200/80">
                  {formatCreatedAt(artifact.created_at, locale)}
                </p>
                <div className="grid grid-cols-2 gap-2">
                  <a
                    href={resolveArtifactImageUrl(artifact.image_url)}
                    download={`era-${artifact.public_hash}.png`}
                    className="btn-secondary justify-center text-xs"
                    onClick={(event) => event.stopPropagation()}
                  >
                    {t('download')}
                  </a>
                  {onVerifyImage ? (
                    <button
                      type="button"
                      className="btn-primary justify-center text-xs"
                      onClick={() => onVerifyImage(artifact.image_url)}
                    >
                      {t('verify')}
                    </button>
                  ) : null}
                </div>
              </div>
            </article>
          ))}
        </div>
      )}

      {pages > 1 ? (
        <div className="mt-6 flex items-center justify-center gap-3">
          <button
            type="button"
            className="btn-secondary"
            disabled={page <= 1 || isLoading}
            onClick={() => onPageChange(page - 1)}
          >
            {t('previous')}
          </button>
          <span className="font-mono text-sm text-parchment-400">
            {t('page')} {page} / {pages}
          </span>
          <button
            type="button"
            className="btn-secondary"
            disabled={page >= pages || isLoading}
            onClick={() => onPageChange(page + 1)}
          >
            {t('next')}
          </button>
        </div>
      ) : null}

      {lightbox ? (
        <ImageLightbox
          src={resolveArtifactImageUrl(lightbox.image_url)}
          alt={`Artifact ${lightbox.public_hash}`}
          hash={lightbox.public_hash}
          createdAt={formatCreatedAt(lightbox.created_at, locale)}
          onClose={() => setLightbox(null)}
          onVerify={
            onVerifyImage
              ? () => {
                  setLightbox(null)
                  onVerifyImage(lightbox.image_url)
                }
              : undefined
          }
        />
      ) : null}
    </section>
  )
}
