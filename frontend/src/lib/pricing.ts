/** Pro checkout URL (Lemon Squeezy, Paddle, Gumroad, or Stripe). */
export function getProPaymentLink(): string | null {
  const generic = import.meta.env.VITE_PRO_PAYMENT_LINK?.trim()
  if (generic) return generic
  const legacyStripe = import.meta.env.VITE_STRIPE_PRO_LINK?.trim()
  return legacyStripe || null
}

export const LIVE_APP_URL = 'https://frontend-flax-two-11q4abvz2o.vercel.app'
export const GITHUB_URL = 'https://github.com/R1M1R/ERA'
export const PRO_CONTACT_EMAIL = 'era-pro@r1m1r.dev'
