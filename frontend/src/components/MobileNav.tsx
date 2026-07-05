import { useI18n } from '../hooks/useI18n'

const SECTIONS = [
  { id: 'generate-section', key: 'navGenerate' as const },
  { id: 'pipeline-section', key: 'navPipeline' as const },
  { id: 'gallery-section', key: 'navGallery' as const },
  { id: 'decoder-section', key: 'navDecoder' as const },
  { id: 'pricing-section', key: 'navPricing' as const },
  { id: 'pro-section', key: 'navPro' as const },
] as const

export function MobileNav() {
  const { t } = useI18n()

  return (
    <nav
      className="fixed bottom-0 left-0 right-0 z-40 border-t border-archive-700/80 bg-archive-950/95 px-2 py-2 backdrop-blur-md sm:hidden"
      aria-label="Mobile navigation"
    >
      <ul className="flex items-center justify-around">
        {SECTIONS.map((section) => (
          <li key={section.id}>
            <a
              href={`#${section.id}`}
              className="flex flex-col items-center gap-0.5 rounded-lg px-3 py-1.5 text-[10px] font-medium text-parchment-400 transition active:bg-archive-800 active:text-parchment-100"
            >
              <span className="text-base" aria-hidden="true">
                {section.id === 'generate-section'
                  ? '✦'
                  : section.id === 'pipeline-section'
                    ? '⟳'
                    : section.id === 'gallery-section'
                      ? '▦'
                      : section.id === 'decoder-section'
                        ? '◎'
                        : section.id === 'pricing-section'
                          ? '◈'
                          : section.id === 'pro-section'
                            ? '★'
                            : '•'}
              </span>
              {t(section.key)}
            </a>
          </li>
        ))}
      </ul>
    </nav>
  )
}
