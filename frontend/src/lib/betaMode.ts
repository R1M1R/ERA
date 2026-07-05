/** Beta / test-mode flags for ERA public rollout. */

export function isBetaNoticeEnabled(): boolean {
  const flag = import.meta.env.VITE_APP_BETA_MODE?.trim().toLowerCase()
  return flag !== 'false' && flag !== '0' && flag !== 'off'
}

/** Pro checkout is allowed only when production infrastructure is fully configured. */
export function isProCheckoutEnabled(productionReady: boolean): boolean {
  return productionReady
}
