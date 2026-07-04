interface ToastProps {
  message: string
  variant?: 'success' | 'error' | 'info'
  onDismiss: () => void
}

const VARIANT_CLASS = {
  success: 'border-emerald-500/40 bg-emerald-500/15 text-emerald-100',
  error: 'border-red-500/40 bg-red-500/15 text-red-100',
  info: 'border-parchment-500/40 bg-parchment-500/15 text-parchment-100',
} as const

export function Toast({ message, variant = 'success', onDismiss }: ToastProps) {
  return (
    <div
      role="status"
      className={`animate-fade-in-up fixed bottom-6 right-6 z-50 flex max-w-sm items-start gap-3 rounded-xl border px-4 py-3 shadow-glow ${VARIANT_CLASS[variant]}`}
    >
      <p className="flex-1 text-sm font-medium">{message}</p>
      <button
        type="button"
        onClick={onDismiss}
        className="rounded-md px-1 text-xs opacity-70 transition hover:opacity-100"
        aria-label="Dismiss notification"
      >
        ✕
      </button>
    </div>
  )
}
