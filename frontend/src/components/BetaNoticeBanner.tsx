import { useI18n } from '../hooks/useI18n'
import { isBetaNoticeEnabled } from '../lib/betaMode'

interface BetaNoticeBannerProps {
  productionReady: boolean
}

export function BetaNoticeBanner({ productionReady }: BetaNoticeBannerProps) {
  const { t } = useI18n()

  if (!isBetaNoticeEnabled()) {
    return null
  }

  const proUnavailable = !productionReady

  return (
    <div
      role="alert"
      aria-live="polite"
      className={`panel mb-8 border ${
        proUnavailable
          ? 'border-amber-400/50 bg-gradient-to-r from-amber-500/15 via-amber-500/5 to-transparent'
          : 'border-sky-400/40 bg-gradient-to-r from-sky-500/10 to-transparent'
      }`}
    >
      <div className="flex flex-wrap items-start gap-4">
        <span className="shrink-0 rounded-full border border-amber-400/60 bg-amber-500/20 px-3 py-1 text-[10px] font-bold uppercase tracking-[0.2em] text-amber-100">
          {t('betaBadge')}
        </span>
        <div className="min-w-0 flex-1">
          <p className="font-display text-lg text-parchment-50">{t('betaTitle')}</p>
          <p className="mt-2 text-sm leading-relaxed text-parchment-200/90">
            {proUnavailable ? t('betaDescProUnavailable') : t('betaDesc')}
          </p>
          {proUnavailable ? (
            <p className="mt-2 text-sm font-medium text-amber-100/95">{t('betaProWarning')}</p>
          ) : null}
        </div>
      </div>
    </div>
  )
}
