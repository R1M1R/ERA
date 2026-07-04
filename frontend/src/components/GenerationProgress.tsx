import { PIPELINE_STEPS, getStepIndex } from '../lib/pipeline'
import type { TaskStatusResponse } from '../types/api'

interface GenerationProgressProps {
  taskId: string | null
  status: TaskStatusResponse | null
  isPolling: boolean
  error: string | null
  onReset: () => void
}

function statusLabel(status: TaskStatusResponse['status'] | undefined): string {
  switch (status) {
    case 'queued':
      return 'Queued'
    case 'running':
      return 'Running'
    case 'completed':
      return 'Completed'
    case 'failed':
      return 'Failed'
    default:
      return 'Idle'
  }
}

export function GenerationProgress({
  taskId,
  status,
  isPolling,
  error,
  onReset,
}: GenerationProgressProps) {
  const activeIndex =
    status?.status === 'completed'
      ? PIPELINE_STEPS.length - 1
      : getStepIndex(status?.step)

  const imageSrc = status?.result?.image_base64
    ? `data:image/png;base64,${status.result.image_base64}`
    : null

  return (
    <section className="panel">
      <div className="mb-5 flex items-start justify-between gap-4">
        <div>
          <h2 className="font-display text-2xl text-parchment-50">Generation pipeline</h2>
          <p className="mt-1 text-sm text-parchment-200/70">
            Polling <span className="font-mono text-parchment-400">GET /status/&lt;id&gt;</span> until
            the artifact is ready.
          </p>
        </div>
        <span className="rounded-full border border-archive-600 bg-archive-800 px-3 py-1 text-xs font-medium text-parchment-300">
          {status ? statusLabel(status.status) : 'Idle'}
        </span>
      </div>

      {!taskId ? (
        <div className="rounded-xl border border-dashed border-archive-700 bg-archive-950/40 px-6 py-10 text-center text-sm text-archive-600">
          Start autonomous generation to watch the pipeline progress.
        </div>
      ) : (
        <div className="space-y-6">
          <div className="rounded-xl border border-archive-700 bg-archive-950/50 px-4 py-3 font-mono text-xs text-parchment-300">
            task_id: {taskId}
            {isPolling ? <span className="ml-3 text-parchment-500">polling...</span> : null}
          </div>

          <ol className="space-y-4">
            {PIPELINE_STEPS.map((step, index) => {
              const isDone = activeIndex > index || status?.status === 'completed'
              const isActive = activeIndex === index && status?.status !== 'completed' && status?.status !== 'failed'

              return (
                <li
                  key={step.id}
                  className={`rounded-xl border px-4 py-4 transition ${
                    isActive
                      ? 'border-parchment-500/50 bg-parchment-500/10'
                      : isDone
                        ? 'border-emerald-500/30 bg-emerald-500/5'
                        : 'border-archive-700 bg-archive-950/30'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span
                      className={`flex h-8 w-8 items-center justify-center rounded-full text-sm font-semibold ${
                        isDone
                          ? 'bg-emerald-500/20 text-emerald-300'
                          : isActive
                            ? 'bg-parchment-500/20 text-parchment-300 animate-pulse-slow'
                            : 'bg-archive-800 text-archive-600'
                      }`}
                    >
                      {index + 1}
                    </span>
                    <div>
                      <p className="font-medium text-parchment-100">{step.label}</p>
                      <p className="text-sm text-parchment-200/60">{step.description}</p>
                    </div>
                  </div>
                </li>
              )
            })}
          </ol>

          {status?.status === 'failed' ? (
            <p className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
              {status.error ?? error ?? 'Generation failed.'}
            </p>
          ) : null}

          {error && status?.status !== 'failed' ? (
            <p className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
              {error}
            </p>
          ) : null}

          {status?.status === 'completed' && status.result ? (
            <div className="grid gap-4 lg:grid-cols-[240px_1fr]">
              {imageSrc ? (
                <div className="overflow-hidden rounded-xl border border-archive-700 bg-archive-950">
                  <img src={imageSrc} alt="Generated artifact" className="h-full w-full object-cover" />
                </div>
              ) : null}
              <div className="rounded-xl border border-archive-700 bg-archive-950/60 p-4">
                <p className="mb-2 text-xs font-semibold uppercase tracking-[0.2em] text-parchment-500">
                  Generated riddle
                </p>
                <pre className="max-h-64 overflow-auto whitespace-pre-wrap font-mono text-sm leading-relaxed text-parchment-100">
                  {status.result.riddle ?? status.result.embedded_text ?? 'Riddle embedded successfully.'}
                </pre>
                {status.result.answer ? (
                  <p className="mt-3 rounded-lg border border-parchment-500/20 bg-parchment-500/5 px-3 py-2 text-sm text-parchment-200">
                    <span className="font-semibold text-parchment-400">Answer:</span> {status.result.answer}
                  </p>
                ) : null}
                {imageSrc ? (
                  <a
                    href={imageSrc}
                    download={`era-artifact-${taskId}.png`}
                    className="btn-secondary mt-4 inline-flex"
                  >
                    Download PNG
                  </a>
                ) : null}
              </div>
            </div>
          ) : null}

          {taskId ? (
            <button type="button" className="btn-secondary" onClick={onReset}>
              Start new generation
            </button>
          ) : null}
        </div>
      )}
    </section>
  )
}
