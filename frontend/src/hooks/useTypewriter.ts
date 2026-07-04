import { useEffect, useState } from 'react'

interface UseTypewriterOptions {
  speedMs?: number
  enabled?: boolean
}

export function useTypewriter(text: string, options: UseTypewriterOptions = {}) {
  const { speedMs = 24, enabled = true } = options
  const [displayedText, setDisplayedText] = useState('')
  const [isComplete, setIsComplete] = useState(false)

  useEffect(() => {
    if (!enabled || !text) {
      setDisplayedText(text)
      setIsComplete(Boolean(text))
      return
    }

    setDisplayedText('')
    setIsComplete(false)

    let index = 0
    const intervalId = window.setInterval(() => {
      index += 1
      setDisplayedText(text.slice(0, index))

      if (index >= text.length) {
        window.clearInterval(intervalId)
        setIsComplete(true)
      }
    }, speedMs)

    return () => {
      window.clearInterval(intervalId)
    }
  }, [text, speedMs, enabled])

  return { displayedText, isComplete }
}
