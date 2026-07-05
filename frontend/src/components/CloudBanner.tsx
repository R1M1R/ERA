import { useI18n } from '../hooks/useI18n'

export function CloudBanner() {
  const { t } = useI18n()

  return (
    <div className="panel mb-8 flex flex-wrap items-center justify-between gap-4 border-parchment-500/20 bg-gradient-to-r from-parchment-500/5 to-transparent">
      <div>
        <p className="font-display text-lg text-parchment-100">{t('cloudTitle')}</p>
        <p className="mt-1 max-w-xl text-sm text-parchment-300/80">{t('cloudDesc')}</p>
      </div>
      <div className="flex flex-wrap gap-2">
        <a
          href="https://render.com/deploy?repo=https://github.com/R1M1R/ERA"
          target="_blank"
          rel="noreferrer"
          className="btn-primary"
        >
          {t('cloudBtn')}
        </a>
        <span className="btn-secondary cursor-default opacity-80">{t('cloudLocal')}: install-auto-start.ps1</span>
      </div>
    </div>
  )
}
