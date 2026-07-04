import { useEffect, useState } from 'react'

import { useI18n } from '../hooks/useI18n'

const SECTION_IDS = ['generate-section', 'pipeline-section', 'gallery-section', 'decoder-section'] as const

export function SectionNav() {
  const { t } = useI18n()
  const [active, setActive] = useState<string>('generate-section')

  const sections = [
    { id: 'generate-section', label: t('navGenerate') },
    { id: 'pipeline-section', label: t('navPipeline') },
    { id: 'gallery-section', label: t('navGallery') },
    { id: 'decoder-section', label: t('navDecoder') },
  ]

  useEffect(() => {
    const observers: IntersectionObserver[] = []

    for (const id of SECTION_IDS) {
      const element = document.getElementById(id)
      if (!element) continue

      const observer = new IntersectionObserver(
        (entries) => {
          for (const entry of entries) {
            if (entry.isIntersecting) {
              setActive(id)
            }
          }
        },
        { rootMargin: '-20% 0px -60% 0px', threshold: 0 },
      )
      observer.observe(element)
      observers.push(observer)
    }

    return () => {
      for (const observer of observers) {
        observer.disconnect()
      }
    }
  }, [])

  return (
    <nav
      aria-label="Page sections"
      className="sticky top-0 z-40 -mx-4 mb-8 border-b border-archive-700/60 bg-archive-950/85 px-4 py-3 backdrop-blur-md sm:-mx-6 sm:px-6 lg:-mx-8 lg:px-8"
    >
      <ul className="mx-auto flex max-w-6xl flex-wrap items-center justify-center gap-1 sm:gap-2">
        {sections.map((section) => (
          <li key={section.id}>
            <a
              href={`#${section.id}`}
              className={`rounded-lg px-3 py-1.5 text-xs font-medium transition sm:px-4 sm:text-sm ${
                active === section.id
                  ? 'bg-parchment-500/15 text-parchment-100'
                  : 'text-parchment-400 hover:bg-archive-800 hover:text-parchment-50'
              }`}
            >
              {section.label}
            </a>
          </li>
        ))}
      </ul>
    </nav>
  )
}
