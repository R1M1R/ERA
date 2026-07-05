import { useState } from 'react'

import { useI18n } from '../hooks/useI18n'
import { activateProByEmail, fetchProStatus } from '../lib/api'
import { getProPaymentLink } from '../lib/pricing'
import { setProKey, clearProKey } from '../lib/proKey'
import { isProCheckoutEnabled } from '../lib/betaMode'
import type { ProInfo } from '../hooks/useProStatus'

interface ProSectionProps {
  pro: ProInfo
  productionReady: boolean
}

export function ProSection({ pro, productionReady }: ProSectionProps) {
  const { t } = useI18n()
  const paymentLink = getProPaymentLink()
  const checkoutEnabled = isProCheckoutEnabled(productionReady)
  const [email, setEmail] = useState('')
  const [manualKey, setManualKey] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [isActivating, setIsActivating] = useState(false)

  const saveKey = async (key: string) => {
    setProKey(key)
    setError(null)
    await pro.refresh()
  }

  const activateByEmail = async () => {
    setIsActivating(true)
    setError(null)
    try {
      const response = await activateProByEmail(email.trim())
      await saveKey(response.api_key)
    } catch (activateError) {
      const message =
        activateError instanceof Error ? activateError.message : t('proActivateError')
      setError(message)
    } finally {
      setIsActivating(false)
    }
  }

  const activateByKey = async () => {
    const key = manualKey.trim()
    if (!key) return
    setIsActivating(true)
    setError(null)
    try {
      setProKey(key)
      const status = await fetchProStatus()
      if (!status.active) {
        setError(t('proKeyInvalid'))
        clearProKey()
      }
      await pro.refresh()
    } finally {
      setIsActivating(false)
    }
  }

  const disconnect = () => {
    pro.disconnect()
    setManualKey('')
  }

  return (
    <section className="panel animate-fade-in-up" id="pro-section">
      <div className="mb-6 text-center">
        <p className="text-xs font-semibold uppercase tracking-[0.3em] text-parchment-500">{t('proEyebrow')}</p>
        <h2 className="mt-2 font-display text-2xl text-parchment-50 sm:text-3xl">{t('proTitle')}</h2>
        <p className="mx-auto mt-2 max-w-2xl text-sm text-parchment-300/80">{t('proDesc')}</p>
      </div>

      {pro.statusError ? (
        <p className="mb-4 rounded-xl border border-amber-500/30 bg-amber-500/10 px-4 py-3 text-sm text-amber-200">
          {t('proStatusError')}
        </p>
      ) : null}

      {!checkoutEnabled ? (
        <p className="mb-4 rounded-xl border border-amber-500/35 bg-amber-500/10 px-4 py-3 text-sm text-amber-100">
          {t('betaProWarning')}
        </p>
      ) : null}

      {pro.active ? (
        <div className="rounded-2xl border border-emerald-500/30 bg-emerald-500/10 p-5">
          <p className="text-sm font-semibold text-emerald-200">{t('proActive')}</p>
          {pro.email ? (
            <p className="mt-1 text-sm text-emerald-100/80">
              {t('proEmail')}: {pro.email}
            </p>
          ) : null}
          <p className="mt-2 text-sm text-emerald-100/70">
            {pro.openaiForPro ? t('proOpenAiReady') : t('proOpenAiPending')}
          </p>
          <button type="button" className="btn-secondary mt-4" onClick={disconnect}>
            {t('proDisconnect')}
          </button>
        </div>
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          <article className="rounded-2xl border border-archive-600 bg-archive-900/50 p-5">
            <h3 className="font-display text-lg text-parchment-100">{t('proStep1')}</h3>
            <p className="mt-2 text-sm text-parchment-300/80">{t('proStep1Desc')}</p>
            {checkoutEnabled && paymentLink ? (
              <a href={paymentLink} target="_blank" rel="noreferrer" className="btn-primary mt-4 inline-block">
                {t('pricingUpgrade')}
              </a>
            ) : (
              <p className="mt-4 text-sm text-amber-100/90">{t('pricingProUnavailable')}</p>
            )}
          </article>

          <article className="rounded-2xl border border-parchment-500/30 bg-parchment-500/5 p-5">
            <h3 className="font-display text-lg text-parchment-100">{t('proStep2')}</h3>
            <p className="mt-2 text-sm text-parchment-300/80">{t('proStep2Desc')}</p>
            <div className="mt-4 flex flex-col gap-2">
              <label htmlFor="pro-email" className="text-xs font-medium text-parchment-400">
                {t('proEmailLabel')}
              </label>
              <input
                id="pro-email"
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                placeholder={t('proEmailPlaceholder')}
                autoComplete="email"
                className="rounded-xl border border-archive-600 bg-archive-950 px-4 py-2 text-sm text-parchment-100"
              />
              <button
                type="button"
                className="btn-primary"
                disabled={isActivating || !email.trim()}
                onClick={() => void activateByEmail()}
              >
                {isActivating ? t('proActivating') : t('proActivateBtn')}
              </button>
            </div>
          </article>

          <article className="rounded-2xl border border-archive-600 bg-archive-900/50 p-5 md:col-span-2">
            <h3 className="font-display text-lg text-parchment-100">{t('proStep3')}</h3>
            <p className="mt-2 text-sm text-parchment-300/80">{t('proStep3Desc')}</p>
            <div className="mt-4 flex flex-col gap-2 sm:flex-row">
              <label htmlFor="pro-key" className="sr-only">
                {t('proKeyLabel')}
              </label>
              <input
                id="pro-key"
                type="text"
                value={manualKey}
                onChange={(event) => setManualKey(event.target.value)}
                placeholder={t('proKeyPlaceholder')}
                autoComplete="off"
                className="min-w-0 flex-1 rounded-xl border border-archive-600 bg-archive-950 px-4 py-2 font-mono text-sm text-parchment-100"
              />
              <button
                type="button"
                className="btn-secondary shrink-0"
                disabled={isActivating || !manualKey.trim()}
                onClick={() => void activateByKey()}
              >
                {t('proSaveKey')}
              </button>
            </div>
          </article>
        </div>
      )}

      {error ? (
        <p className="mt-4 rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
          {error}
        </p>
      ) : null}
    </section>
  )
}
