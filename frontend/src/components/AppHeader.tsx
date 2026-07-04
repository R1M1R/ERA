import { getApiBaseUrl } from '../lib/api'

export function AppHeader() {
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
      <p className="mt-3 font-mono text-xs text-archive-600">API: {getApiBaseUrl()}</p>
    </header>
  )
}
