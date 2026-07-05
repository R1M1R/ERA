import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'

import { I18nContext, type I18nContextValue } from '../contexts/i18nContext'
import { translate, type Locale } from '../lib/i18n'

const STORAGE_KEY = 'era-locale'

function detectLocale(): Locale {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    if (stored === 'ru' || stored === 'en') return stored
    const lang = navigator.language.toLowerCase()
    if (lang.startsWith('ru')) return 'ru'
    return 'en'
  } catch {
    return 'en'
  }
}

export function I18nProvider({ children }: { children: ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>(detectLocale)

  const setLocale = useCallback((next: Locale) => {
    setLocaleState(next)
    document.documentElement.lang = next
    try {
      localStorage.setItem(STORAGE_KEY, next)
    } catch {
      // ignore
    }
  }, [])

  const value = useMemo<I18nContextValue>(
    () => ({
      locale,
      setLocale,
      t: (key) => translate(locale, key),
    }),
    [locale, setLocale],
  )

  useEffect(() => {
    document.documentElement.lang = locale
  }, [locale])

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>
}
