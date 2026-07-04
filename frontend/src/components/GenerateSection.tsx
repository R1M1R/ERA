interface GenerateSectionProps {
  isSubmitting: boolean
  isApiReady: boolean
  error: string | null
  onSubmit: () => Promise<void>
}

export function GenerateSection({ isSubmitting, isApiReady, error, onSubmit }: GenerateSectionProps) {
  return (
    <section className="panel">
      <div className="mb-5 flex items-start justify-between gap-4">
        <div>
          <h2 className="font-display text-2xl text-parchment-50">Autonomous generation</h2>
          <p className="mt-1 text-sm text-parchment-200/70">
            The AI orchestrator creates a historical riddle, seals it inside a procedural artifact,
            and publishes it to the archive gallery.
          </p>
        </div>
        <span className="rounded-full border border-parchment-500/30 bg-parchment-500/10 px-3 py-1 text-xs font-medium text-parchment-300">
          POST /generate
        </span>
      </div>

      {isApiReady ? (
        <p className="mb-4 rounded-xl border border-emerald-500/30 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-200">
          Product ready — click Generate to create your first artifact (~5 seconds in demo mode).
        </p>
      ) : (
        <p className="mb-4 rounded-xl border border-amber-500/30 bg-amber-500/10 px-4 py-3 text-sm text-amber-200">
          API offline — run <span className="font-mono">GO.bat</span> or{' '}
          <span className="font-mono">.\scripts\restart-era.ps1</span>
        </p>
      )}

      {error ? (
        <p className="mb-4 rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
          {error}
        </p>
      ) : null}

      <button type="button" className="btn-primary" disabled={isSubmitting || !isApiReady} onClick={() => void onSubmit()}>
        {isSubmitting ? 'Queueing artifact...' : 'Generate new artifact'}
      </button>
    </section>
  )
}
