import { useI18n } from '../hooks/useI18n'
import { GITHUB_URL, LIVE_APP_URL } from '../lib/pricing'

export function AppFooter() {
  const { t } = useI18n()

  return (
    <footer className="mt-12 border-t border-archive-700/60 py-8 text-center">
      <div className="flex flex-wrap items-center justify-center gap-4 text-sm text-parchment-400">
        <a
          href={GITHUB_URL}
          target="_blank"
          rel="noreferrer"
          className="transition hover:text-parchment-200"
        >
          {t('footerGithub')}
        </a>
        <span className="text-archive-600">·</span>
        <a
          href={LIVE_APP_URL}
          target="_blank"
          rel="noreferrer"
          className="transition hover:text-parchment-200"
        >
          {t('footerLive')}
        </a>
        <span className="text-archive-600">·</span>
        <a href="#pricing-section" className="transition hover:text-parchment-200">
          {t('navPricing')}
        </a>
      </div>
      <p className="mt-3 text-xs text-archive-600">ERA · International SaaS · LSB steganography</p>
    </footer>
  )
}
