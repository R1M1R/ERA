interface GenerateSectionProps {
  isSubmitting: boolean
  error: string | null
  onSubmit: () => Promise<void>
}

export function GenerateSection({ isSubmitting, error, onSubmit }: GenerateSectionProps) {
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

      {error ? (
        <p className="mb-4 rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
          {error}
        </p>
      ) : null}

      <button type="button" className="btn-primary" disabled={isSubmitting} onClick={() => void onSubmit()}>
        {isSubmitting ? 'Queueing artifact...' : 'Generate new artifact'}
      </button>
    </section>
  )
}
