import { getApiBaseUrl } from '../lib/api'
import { getStripeProLink } from '../lib/pricing'
import type { ApiHealthState } from '../hooks/useApiHealth'
import { useI18n } from '../hooks/useI18n'
import type { TranslationKey } from '../lib/i18n'

const STATUS_CLASS: Record<ApiHealthState, string> = {
  checking: 'bg-parchment-500',
  ok: 'bg-emerald-500',
  degraded: 'bg-amber-500',
  down: 'bg-red-500',
}

interface AppHeaderProps {
  artifactTotal: number
  apiHealth: ApiHealthState
  demoMode: boolean
  standaloneMode: boolean
}

export function AppHeader({ artifactTotal, apiHealth, demoMode, standaloneMode }: AppHeaderProps) {
  const { t, locale, setLocale } = useI18n()

  const statusKey: TranslationKey =
    apiHealth === 'ok'
      ? 'apiOnline'
      : apiHealth === 'down'
        ? 'apiOffline'
        : apiHealth === 'degraded'
          ? 'apiDegraded'
          : 'apiChecking'

  const stripeLink = getStripeProLink()

  return (
    <header className="mb-2 text-center">
      <div className="mb-4 flex items-center justify-end gap-2">
        {demoMode ? (
          stripeLink ? (
            <a
              href={stripeLink}
              target="_blank"
              rel="noreferrer"
              className="rounded-lg border border-parchment-500/40 bg-parchment-500/15 px-3 py-1 text-xs font-semibold text-parchment-100 transition hover:bg-parchment-500/25"
            >
              {t('headerUpgrade')}
            </a>
          ) : (
            <a
              href="#pricing-section"
              className="rounded-lg border border-parchment-500/40 bg-parchment-500/15 px-3 py-1 text-xs font-semibold text-parchment-100 transition hover:bg-parchment-500/25"
            >
              {t('headerUpgrade')}
            </a>
          )
        ) : null}
        <button
          type="button"
          className="rounded-lg border border-archive-600 bg-archive-800 px-3 py-1 text-xs font-medium text-parchment-300 transition hover:border-parchment-500/40"
          onClick={() => setLocale(locale === 'ru' ? 'en' : 'ru')}
          aria-label="Toggle language"
        >
          {t('lang')}
        </button>
      </div>

      <p className="mb-3 text-xs font-semibold uppercase tracking-[0.35em] text-parchment-500">
        {t('archive')}
      </p>
      <h1 className="font-display text-4xl font-semibold tracking-tight text-parchment-50 sm:text-5xl lg:text-6xl">
        <span className="bg-gradient-to-r from-parchment-100 via-parchment-300 to-parchment-500 bg-clip-text text-transparent">
          {t('title')}
        </span>
      </h1>
      <p className="mx-auto mt-4 max-w-2xl text-sm leading-relaxed text-parchment-200/80 sm:text-base">
        {t('subtitle')}
      </p>

      <div className="mx-auto mt-6 flex max-w-3xl flex-wrap items-center justify-center gap-3">
        <div className="panel flex min-w-[7rem] flex-col items-center px-5 py-3">
          <span className="font-display text-2xl font-semibold text-parchment-100">{artifactTotal}</span>
          <span className="text-[10px] uppercase tracking-wider text-parchment-500">{t('artifacts')}</span>
        </div>
        <div className="panel flex min-w-[7rem] flex-col items-center px-5 py-3">
          <span className="font-display text-2xl font-semibold text-emerald-300">LSB</span>
          <span className="text-[10px] uppercase tracking-wider text-parchment-500">{t('steganography')}</span>
        </div>
        <div className="panel flex min-w-[7rem] flex-col items-center px-5 py-3">
          <span className="font-display text-2xl font-semibold text-parchment-100">SHA</span>
          <span className="text-[10px] uppercase tracking-wider text-parchment-500">{t('verification')}</span>
        </div>
      </div>

      <p className="mt-5 flex flex-wrap items-center justify-center gap-2 font-mono text-xs text-archive-600">
        <span
          className={`inline-block h-2 w-2 rounded-full ${STATUS_CLASS[apiHealth]} ${apiHealth === 'ok' ? 'animate-pulse-slow' : ''}`}
          aria-hidden="true"
        />
        <span>{t(statusKey)}</span>
        {standaloneMode ? (
          <span className="rounded-full border border-archive-600 bg-archive-800 px-2 py-0.5 text-[10px] uppercase tracking-wider text-parchment-400">
            {t('standalone')}
          </span>
        ) : null}
        {demoMode ? (
          <span className="rounded-full border border-parchment-500/30 bg-parchment-500/10 px-2 py-0.5 text-[10px] uppercase tracking-wider text-parchment-300">
            {t('demoAi')}
          </span>
        ) : null}
        <span className="text-parchment-500">·</span>
        <span>{getApiBaseUrl() || 'local proxy'}</span>
      </p>
    </header>
  )
}
