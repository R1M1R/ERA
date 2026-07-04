import { resolveArtifactImageUrl } from '../lib/api'
import type { ArtifactItem } from '../types/api'

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

function formatCreatedAt(value: string): string {
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
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
  return (
    <section className="panel">
      <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
        <div>
          <h2 className="font-display text-2xl text-parchment-50">Gallery</h2>
          <p className="mt-1 text-sm text-parchment-200/70">
            Latest steganographic artifacts recovered from the ERA archive.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <span className="rounded-full border border-archive-600 bg-archive-800 px-3 py-1 text-xs font-medium text-parchment-300">
            {total} artifacts
          </span>
          <button type="button" className="btn-secondary" onClick={onReload}>
            Refresh
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
              className="aspect-square animate-pulse rounded-2xl border border-archive-700 bg-archive-800/60"
            />
          ))}
        </div>
      ) : items.length === 0 ? (
        <div className="rounded-xl border border-dashed border-archive-700 bg-archive-950/40 px-6 py-16 text-center text-sm text-archive-600">
          No artifacts yet. Generate the first chronicle to populate the gallery.
        </div>
      ) : (
        <div className="columns-1 gap-4 sm:columns-2 xl:columns-3 [column-fill:_balance]">
          {items.map((artifact) => (
            <article
              key={artifact.id}
              className="mb-4 break-inside-avoid overflow-hidden rounded-2xl border border-archive-700 bg-archive-950/50 shadow-glow transition hover:border-parchment-500/40"
            >
              <div className="relative overflow-hidden bg-black/30">
                <img
                  src={resolveArtifactImageUrl(artifact.image_url)}
                  alt={`Artifact ${artifact.public_hash.slice(0, 8)}`}
                  className="w-full object-cover transition duration-500 hover:scale-[1.02]"
                  loading="lazy"
                />
                <div className="absolute left-3 top-3">
                  <span
                    className={`rounded-full px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.18em] ${
                      artifact.is_solved
                        ? 'bg-emerald-500/20 text-emerald-300'
                        : 'bg-parchment-500/15 text-parchment-300'
                    }`}
                  >
                    {artifact.is_solved ? 'Solved' : 'Unsolved'}
                  </span>
                </div>
              </div>

              <div className="space-y-2 p-4">
                <p className="font-mono text-xs text-parchment-500">
                  #{artifact.public_hash.slice(0, 12)}
                </p>
                <p className="text-sm text-parchment-200/80">{formatCreatedAt(artifact.created_at)}</p>
                <a
                  href={resolveArtifactImageUrl(artifact.image_url)}
                  download={`era-${artifact.public_hash}.png`}
                  className="btn-secondary inline-flex w-full justify-center"
                >
                  Download PNG
                </a>
                {onVerifyImage ? (
                  <button
                    type="button"
                    className="btn-primary inline-flex w-full justify-center"
                    onClick={() => onVerifyImage(artifact.image_url)}
                  >
                    Verify in Decoder
                  </button>
                ) : null}
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
            Previous
          </button>
          <span className="font-mono text-sm text-parchment-400">
            Page {page} / {pages}
          </span>
          <button
            type="button"
            className="btn-secondary"
            disabled={page >= pages || isLoading}
            onClick={() => onPageChange(page + 1)}
          >
            Next
          </button>
        </div>
      ) : null}
    </section>
  )
}
