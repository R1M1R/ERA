/** Stripe Payment Link for Pro tier (set in Vercel env: VITE_STRIPE_PRO_LINK). */
export function getStripeProLink(): string | null {
  const link = import.meta.env.VITE_STRIPE_PRO_LINK?.trim()
  return link || null
}

export const LIVE_APP_URL = 'https://frontend-flax-two-11q4abvz2o.vercel.app'
export const GITHUB_URL = 'https://github.com/R1M1R/ERA'
export const PRO_CONTACT_EMAIL = 'era-pro@r1m1r.dev'
