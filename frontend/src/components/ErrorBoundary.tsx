import { Component, type ErrorInfo, type ReactNode } from 'react'

import { I18nContext, type I18nContextValue } from '../contexts/i18nContext'
import { translate, type Locale } from '../lib/i18n'

interface ErrorBoundaryProps {
  children: ReactNode
  locale?: Locale
}

interface ErrorBoundaryState {
  hasError: boolean
}

function detectLocale(): Locale {
  try {
    const stored = localStorage.getItem('era-locale')
    if (stored === 'ru' || stored === 'en') return stored
    return navigator.language.toLowerCase().startsWith('ru') ? 'ru' : 'en'
  } catch {
    return 'en'
  }
}

const fallbackI18n: I18nContextValue = {
  locale: 'en',
  setLocale: () => undefined,
  t: (key) => translate('en', key),
}

export class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  state: ErrorBoundaryState = { hasError: false }

  static getDerivedStateFromError(): ErrorBoundaryState {
    return { hasError: true }
  }

  componentDidCatch(error: Error, info: ErrorInfo): void {
    console.error('ERA UI error:', error, info.componentStack)
  }

  private reload = (): void => {
    window.location.reload()
  }

  render(): ReactNode {
    if (!this.state.hasError) {
      return this.props.children
    }

    const locale = this.props.locale ?? detectLocale()
    const t = (key: Parameters<I18nContextValue['t']>[0]) => translate(locale, key)

    return (
      <I18nContext.Provider value={{ ...fallbackI18n, locale, t }}>
        <div className="flex min-h-screen items-center justify-center bg-archive-950 px-6 py-12 text-parchment-100">
          <div className="panel max-w-lg text-center">
            <p className="text-xs font-semibold uppercase tracking-[0.3em] text-parchment-500">
              {t('errorBoundaryEyebrow')}
            </p>
            <h1 className="mt-3 font-display text-2xl text-parchment-50">{t('errorBoundaryTitle')}</h1>
            <p className="mt-3 text-sm text-parchment-300/85">{t('errorBoundaryDesc')}</p>
            <button type="button" className="btn-primary mt-6" onClick={this.reload}>
              {t('errorBoundaryReload')}
            </button>
          </div>
        </div>
      </I18nContext.Provider>
    )
  }
}
