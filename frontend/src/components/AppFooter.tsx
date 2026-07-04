import { useI18n } from '../hooks/useI18n'

export function AppFooter() {
  const { t } = useI18n()

  return (
    <footer className="mt-12 border-t border-archive-700/60 py-8 text-center">
      <div className="flex flex-wrap items-center justify-center gap-4 text-sm text-parchment-400">
        <a
          href="https://github.com/R1M1R/ERA"
          target="_blank"
          rel="noreferrer"
          className="transition hover:text-parchment-200"
        >
          {t('footerGithub')}
        </a>
        <span className="text-archive-600">·</span>
        <span>
          {t('footerLocal')}: <span className="font-mono text-parchment-500">GO.bat</span>
        </span>
        <span className="text-archive-600">·</span>
        <span>
          {t('footerCloud')}: <span className="font-mono text-parchment-500">24x7.bat</span>
        </span>
      </div>
      <p className="mt-3 text-xs text-archive-600">ERA · LSB steganography · server-side verify</p>
    </footer>
  )
}
