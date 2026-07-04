import { getApiBaseUrl } from '../lib/api'
import { useApiHealth } from '../hooks/useApiHealth'

const STATUS_LABEL = {
  checking: 'Checking API…',
  ok: 'API online',
  degraded: 'API degraded',
  down: 'API offline',
} as const

const STATUS_CLASS = {
  checking: 'bg-parchment-500',
  ok: 'bg-emerald-500',
  degraded: 'bg-amber-500',
  down: 'bg-red-500',
} as const

export function AppHeader() {
  const { state: apiHealth, demoMode, standaloneMode } = useApiHealth()

  return (
    <header className="mb-10 text-center">
      <p className="mb-3 text-xs font-semibold uppercase tracking-[0.35em] text-parchment-500">
        ERA Archive
      </p>
      <h1 className="font-display text-4xl font-semibold text-parchment-50 sm:text-5xl">
        Steganographic Historical Artifacts
      </h1>
      <p className="mx-auto mt-4 max-w-2xl text-sm leading-relaxed text-parchment-200/80 sm:text-base">
        Generate pixel artifacts with hidden chronicles, monitor the AI pipeline in real time,
        and decode recovered images with a local Canvas steganography engine.
      </p>
      <p className="mt-3 flex flex-wrap items-center justify-center gap-2 font-mono text-xs text-archive-600">
        <span
          className={`inline-block h-2 w-2 rounded-full ${STATUS_CLASS[apiHealth]}`}
          aria-hidden="true"
        />
        <span>{STATUS_LABEL[apiHealth]}</span>
        {standaloneMode ? (
          <span className="rounded-full border border-archive-600 bg-archive-800 px-2 py-0.5 text-[10px] uppercase tracking-wider text-parchment-400">
            Standalone
          </span>
        ) : null}
        {demoMode ? (
          <span className="rounded-full border border-parchment-500/30 bg-parchment-500/10 px-2 py-0.5 text-[10px] uppercase tracking-wider text-parchment-300">
            Demo
          </span>
        ) : null}
        <span className="text-parchment-500">·</span>
        <span>{getApiBaseUrl()}</span>
      </p>
    </header>
  )
}
