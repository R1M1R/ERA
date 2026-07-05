import { getStepIndex } from '../lib/pipeline'
import { useI18n } from '../hooks/useI18n'
import { getPipelineSteps } from '../lib/i18n'
import type { TaskStatusResponse } from '../types/api'

interface GenerationProgressProps {
  taskId: string | null
  status: TaskStatusResponse | null
  isPolling: boolean
  error: string | null
  onReset: () => void
}

function progressPercent(status: TaskStatusResponse | null, stepCount: number): number {
  if (!status) return 0
  if (status.status === 'completed') return 100
  if (status.status === 'failed') return 0
  if (status.status === 'queued') return 8

  const index = getStepIndex(status.step)
  if (index < 0) return 15
  const stepProgress = ((index + 1) / stepCount) * 85
  return Math.round(10 + stepProgress)
}

export function GenerationProgress({
  taskId,
  status,
  isPolling,
  error,
  onReset,
}: GenerationProgressProps) {
  const { t, locale } = useI18n()
  const steps = getPipelineSteps(locale)

  const statusLabel = (s: TaskStatusResponse['status'] | undefined) => {
    switch (s) {
      case 'queued':
        return t('statusQueued')
      case 'running':
        return t('statusRunning')
      case 'completed':
        return t('statusCompleted')
      case 'failed':
        return t('statusFailed')
      default:
        return t('statusIdle')
    }
  }

  const activeIndex =
    status?.status === 'completed' ? steps.length - 1 : getStepIndex(status?.step)

  const imageSrc = status?.result?.image_base64
    ? `data:image/png;base64,${status.result.image_base64}`
    : null

  const percent = progressPercent(status, steps.length)

  return (
    <section className="panel" id="pipeline-section">
      <div className="mb-5 flex items-start justify-between gap-4">
        <div>
          <h2 className="font-display text-2xl text-parchment-50">{t('pipelineTitle')}</h2>
          <p className="mt-1 text-sm text-parchment-200/70">{t('pipelineDesc')}</p>
        </div>
        <span
          className={`rounded-full border px-3 py-1 text-xs font-medium ${
            status?.status === 'completed'
              ? 'border-emerald-500/40 bg-emerald-500/15 text-emerald-200'
              : status?.status === 'failed'
                ? 'border-red-500/40 bg-red-500/15 text-red-200'
                : 'border-archive-600 bg-archive-800 text-parchment-300'
          }`}
        >
          {status ? statusLabel(status.status) : t('statusIdle')}
        </span>
      </div>

      {!taskId ? (
        <div className="rounded-xl border border-dashed border-archive-700 bg-archive-950/40 px-6 py-12 text-center">
          <p className="text-sm text-archive-600">{t('pipelineIdle')}</p>
          <p className="mt-2 text-xs text-archive-700">{t('pipelineFlow')}</p>
        </div>
      ) : (
        <div className="space-y-6">
          <div className="space-y-2">
            <div className="flex items-center justify-between font-mono text-xs text-parchment-400">
              <span>task_id: {taskId.slice(0, 8)}…</span>
              <span>
                {percent}%{isPolling ? ` · ${t('polling')}` : ''}
              </span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-archive-800">
              <div
                className={`h-full rounded-full transition-all duration-700 ease-out ${
                  status?.status === 'failed'
                    ? 'bg-red-500'
                    : status?.status === 'completed'
                      ? 'bg-emerald-500'
                      : 'bg-parchment-500'
                }`}
                style={{ width: `${percent}%` }}
              />
            </div>
          </div>

          <ol className="space-y-3">
            {steps.map((step, index) => {
              const isDone = activeIndex > index || status?.status === 'completed'
              const isActive =
                activeIndex === index && status?.status !== 'completed' && status?.status !== 'failed'

              return (
                <li
                  key={step.id}
                  className={`rounded-xl border px-4 py-3 transition-all duration-300 ${
                    isActive
                      ? 'border-parchment-500/50 bg-parchment-500/10 shadow-glow'
                      : isDone
                        ? 'border-emerald-500/30 bg-emerald-500/5'
                        : 'border-archive-700 bg-archive-950/30 opacity-60'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span
                      className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-sm font-semibold ${
                        isDone
                          ? 'bg-emerald-500/20 text-emerald-300'
                          : isActive
                            ? 'bg-parchment-500/20 text-parchment-300 animate-pulse-slow'
                            : 'bg-archive-800 text-archive-600'
                      }`}
                    >
                      {isDone ? '✓' : index + 1}
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
              {status.error ?? error ?? t('generationFailed')}
            </p>
          ) : null}

          {error && status?.status !== 'failed' ? (
            <p className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
              {error}
            </p>
          ) : null}

          {status?.status === 'completed' && status.result ? (
            <div className="animate-fade-in-up space-y-4 rounded-xl border border-emerald-500/30 bg-emerald-500/5 p-4">
              <p className="text-sm font-semibold text-emerald-200">{t('sealedSuccess')}</p>
              <div className="grid gap-4 lg:grid-cols-[220px_1fr]">
                {imageSrc ? (
                  <div className="overflow-hidden rounded-xl border border-archive-700 bg-archive-950 shadow-glow">
                    <img src={imageSrc} alt="Generated artifact" className="h-full w-full object-cover" />
                  </div>
                ) : null}
                <div className="rounded-xl border border-archive-700 bg-archive-950/60 p-4">
                  <p className="mb-2 text-xs font-semibold uppercase tracking-[0.2em] text-parchment-500">
                    {t('generatedRiddle')}
                  </p>
                  <pre className="max-h-48 overflow-auto whitespace-pre-wrap font-mono text-sm leading-relaxed text-parchment-100">
                    {status.result.riddle ?? status.result.embedded_text ?? '—'}
                  </pre>
                  {status.result.answer ? (
                    <p className="mt-3 rounded-lg border border-parchment-500/20 bg-parchment-500/5 px-3 py-2 text-sm text-parchment-200">
                      <span className="font-semibold text-parchment-400">{t('answer')}:</span>{' '}
                      {status.result.answer}
                    </p>
                  ) : null}
                  <div className="mt-4 flex flex-wrap gap-2">
                    {imageSrc ? (
                      <a
                        href={imageSrc}
                        download={`era-artifact-${taskId}.png`}
                        className="btn-secondary"
                      >
                        {t('downloadPng')}
                      </a>
                    ) : null}
                    <a href="#gallery-section" className="btn-primary">
                      {t('viewGallery')}
                    </a>
                  </div>
                </div>
              </div>
            </div>
          ) : null}

          {taskId ? (
            <button type="button" className="btn-secondary" onClick={onReset}>
              {t('startNew')}
            </button>
          ) : null}
        </div>
      )}
    </section>
  )
}
