import { useI18n } from '../hooks/useI18n'
import { useApiHealth } from '../hooks/useApiHealth'

interface StatusDashboardProps {
  artifactTotal: number
}

export function StatusDashboard({ artifactTotal }: StatusDashboardProps) {
  const { t } = useI18n()
  const health = useApiHealth()

  const checks = [
    { label: t('statusApi'), ok: health.state === 'ok' },
    { label: t('statusDb'), ok: health.state === 'ok' || health.state === 'degraded' },
    { label: t('statusGenerate'), ok: health.state === 'ok' },
    { label: t('statusGallery'), ok: artifactTotal >= 0 && health.state === 'ok' },
  ]

  const allOk = health.state === 'ok'

  return (
    <div
      className={`panel mb-8 border ${
        allOk ? 'border-emerald-500/25 bg-emerald-500/5' : 'border-amber-500/25 bg-amber-500/5'
      }`}
    >
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.25em] text-parchment-500">
            {t('statusTitle')}
          </p>
          <p className="mt-1 font-display text-lg text-parchment-100">
            {allOk ? t('statusAllOk') : t('statusCheck')}
          </p>
        </div>
        <span
          className={`rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-wider ${
            allOk
              ? 'bg-emerald-500/20 text-emerald-200'
              : 'bg-amber-500/20 text-amber-200'
          }`}
        >
          {allOk ? t('statusReady') : t('statusWaiting')}
        </span>
      </div>

      <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
        {checks.map((check) => (
          <div
            key={check.label}
            className="flex items-center gap-2 rounded-lg border border-archive-700/80 bg-archive-950/40 px-3 py-2"
          >
            <span
              className={`h-2 w-2 rounded-full ${check.ok ? 'bg-emerald-400' : 'bg-amber-400 animate-pulse-slow'}`}
            />
            <span className="text-sm text-parchment-300">{check.label}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
