import { useI18n } from '../hooks/useI18n'
import { getProPaymentLink, PRO_CONTACT_EMAIL } from '../lib/pricing'

export function PricingSection() {
  const { t } = useI18n()
  const paymentLink = getProPaymentLink()

  return (
    <section className="panel animate-fade-in-up" id="pricing-section">
      <div className="mb-6 text-center">
        <p className="text-xs font-semibold uppercase tracking-[0.3em] text-parchment-500">{t('pricingEyebrow')}</p>
        <h2 className="mt-2 font-display text-2xl text-parchment-50 sm:text-3xl">{t('pricingTitle')}</h2>
        <p className="mx-auto mt-2 max-w-2xl text-sm text-parchment-300/80">{t('pricingDesc')}</p>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <article className="rounded-2xl border border-archive-600 bg-archive-900/50 p-5">
          <h3 className="font-display text-lg text-parchment-100">{t('pricingFreeName')}</h3>
          <p className="mt-1 text-3xl font-semibold text-parchment-50">
            $0 <span className="text-sm font-normal text-parchment-400">{t('pricingPerMonth')}</span>
          </p>
          <ul className="mt-4 space-y-2 text-sm text-parchment-300">
            <li>✓ {t('pricingFree1')}</li>
            <li>✓ {t('pricingFree2')}</li>
            <li>✓ {t('pricingFree3')}</li>
          </ul>
          <p className="mt-4 text-xs text-parchment-500">{t('pricingFreeNote')}</p>
        </article>

        <article className="relative rounded-2xl border border-parchment-500/40 bg-gradient-to-b from-parchment-500/10 to-archive-900/80 p-5 shadow-lg shadow-parchment-500/5">
          <span className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-parchment-500 px-3 py-0.5 text-[10px] font-bold uppercase tracking-wider text-archive-950">
            {t('pricingPopular')}
          </span>
          <h3 className="font-display text-lg text-parchment-100">{t('pricingProName')}</h3>
          <p className="mt-1 text-3xl font-semibold text-parchment-50">
            $12 <span className="text-sm font-normal text-parchment-400">{t('pricingPerMonth')}</span>
          </p>
          <ul className="mt-4 space-y-2 text-sm text-parchment-200">
            <li>✓ {t('pricingPro1')}</li>
            <li>✓ {t('pricingPro2')}</li>
            <li>✓ {t('pricingPro3')}</li>
            <li>✓ {t('pricingPro4')}</li>
          </ul>
          {paymentLink ? (
            <>
              <a href={paymentLink} target="_blank" rel="noreferrer" className="btn-primary mt-5 block w-full text-center">
                {t('pricingUpgrade')}
              </a>
              <a href="#pro-section" className="mt-3 block text-center text-xs text-parchment-400 transition hover:text-parchment-200">
                {t('pricingActivateAfter')}
              </a>
            </>
          ) : (
            <a
              href={`mailto:${PRO_CONTACT_EMAIL}?subject=ERA%20Pro`}
              className="btn-primary mt-5 block w-full text-center"
            >
              {t('pricingContactPro')}
            </a>
          )}
        </article>

        <article className="rounded-2xl border border-archive-600 bg-archive-900/50 p-5">
          <h3 className="font-display text-lg text-parchment-100">{t('pricingBizName')}</h3>
          <p className="mt-1 text-3xl font-semibold text-parchment-50">{t('pricingCustom')}</p>
          <ul className="mt-4 space-y-2 text-sm text-parchment-300">
            <li>✓ {t('pricingBiz1')}</li>
            <li>✓ {t('pricingBiz2')}</li>
            <li>✓ {t('pricingBiz3')}</li>
          </ul>
          <a
            href={`mailto:${PRO_CONTACT_EMAIL}?subject=ERA%20Enterprise`}
            className="btn-secondary mt-5 block w-full text-center"
          >
            {t('pricingContactSales')}
          </a>
        </article>
      </div>

      <p className="mt-6 text-center text-xs text-parchment-500">{t('pricingPassive')}</p>
    </section>
  )
}
