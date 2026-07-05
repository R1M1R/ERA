const STORAGE_KEY = 'era_pro_key'

export function getProKey(): string | null {
  try {
    const value = localStorage.getItem(STORAGE_KEY)?.trim()
    return value || null
  } catch {
    return null
  }
}

export function setProKey(key: string): void {
  localStorage.setItem(STORAGE_KEY, key.trim())
}

export function clearProKey(): void {
  localStorage.removeItem(STORAGE_KEY)
}
