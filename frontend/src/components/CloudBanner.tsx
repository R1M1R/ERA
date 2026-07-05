import { useI18n } from '../hooks/useI18n'
import { GITHUB_URL } from '../lib/pricing'

interface CloudBannerProps {
  visible: boolean
}

export function CloudBanner({ visible }: CloudBannerProps) {
  const { t } = useI18n()

  if (!visible) return null

  return (
    <div className="panel mb-8 flex flex-wrap items-center justify-between gap-4 border-amber-500/30 bg-gradient-to-r from-amber-500/10 to-transparent">
      <div>
        <p className="font-display text-lg text-parchment-100">{t('cloudTitle')}</p>
        <p className="mt-1 max-w-xl text-sm text-parchment-300/80">{t('cloudDesc')}</p>
        <p className="mt-2 text-xs text-parchment-400">
          <a
            href={GITHUB_URL}
            target="_blank"
            rel="noreferrer"
            className="underline decoration-parchment-500/40 underline-offset-2 hover:text-parchment-200"
          >
            {t('cloudRepo')}
          </a>
        </p>
      </div>
      <button type="button" className="btn-primary" onClick={() => window.location.reload()}>
        {t('cloudBtn')}
      </button>
    </div>
  )
}
