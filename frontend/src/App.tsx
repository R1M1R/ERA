import { useCallback, useEffect, useState } from 'react'

import { GenerateSection } from './components/GenerateSection'
import { AppHeader } from './components/AppHeader'
import { DecoderSection } from './components/DecoderSection'
import { GallerySection } from './components/GallerySection'
import { GenerationProgress } from './components/GenerationProgress'
import { PricingSection } from './components/PricingSection'
import { AppFooter } from './components/AppFooter'
import { CloudBanner } from './components/CloudBanner'
import { KeyboardHelp } from './components/KeyboardHelp'
import { MobileNav } from './components/MobileNav'
import { StatusDashboard } from './components/StatusDashboard'
import { WelcomeModal } from './components/WelcomeModal'
import { SectionNav } from './components/SectionNav'
import { Toast } from './components/Toast'
import { useI18n } from './hooks/useI18n'
import { useArtifacts } from './hooks/useArtifacts'
import { useDecoder } from './hooks/useDecoder'
import { useApiHealth } from './hooks/useApiHealth'
import { useGeneration } from './hooks/useGeneration'
import { resolveArtifactImageUrl } from './lib/api'

interface ToastState {
  message: string
  variant: 'success' | 'error' | 'info'
}

function App() {
  const { t } = useI18n()
  const [galleryRefreshKey, setGalleryRefreshKey] = useState(0)
  const [toast, setToast] = useState<ToastState | null>(null)

  const refreshGallery = useCallback(() => {
    setGalleryRefreshKey((value) => value + 1)
  }, [])

  const showToast = useCallback((message: string, variant: ToastState['variant'] = 'success') => {
    setToast({ message, variant })
    window.setTimeout(() => setToast(null), 5000)
  }, [])

  const onGenerationCompleted = useCallback(() => {
    refreshGallery()
    showToast(t('toastSealed'))
    window.setTimeout(() => {
      document.getElementById('gallery-section')?.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }, 400)
  }, [refreshGallery, showToast, t])

  const generation = useGeneration(onGenerationCompleted)
  const gallery = useArtifacts({ refreshKey: galleryRefreshKey })
  const decoder = useDecoder()
  const apiHealth = useApiHealth()

  const verifyGalleryImage = useCallback(
    async (imageUrl: string) => {
      try {
        const response = await fetch(resolveArtifactImageUrl(imageUrl))
        if (!response.ok) {
          throw new Error('Failed to load artifact image.')
        }
        const blob = await response.blob()
        const file = new File([blob], 'era-artifact.png', { type: blob.type || 'image/png' })
        decoder.selectFile(file)
        document.getElementById('decoder-section')?.scrollIntoView({ behavior: 'smooth', block: 'start' })
        showToast(t('toastDecoder'), 'info')
      } catch (loadError) {
        const message = loadError instanceof Error ? loadError.message : 'Failed to load image.'
        showToast(message, 'error')
      }
    },
    [decoder, showToast, t],
  )

  useEffect(() => {
    if (generation.taskId) {
      document.getElementById('pipeline-section')?.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }, [generation.taskId])

  return (
    <div className="mx-auto min-h-screen max-w-6xl px-4 py-8 pb-20 sm:px-6 sm:pb-8 lg:px-8">
      <AppHeader
        artifactTotal={gallery.total}
        apiHealth={apiHealth.state}
        demoMode={apiHealth.demoMode}
        standaloneMode={apiHealth.standaloneMode}
      />

      <SectionNav />

      <StatusDashboard artifactTotal={gallery.total} />

      <CloudBanner visible={apiHealth.state === 'down' || apiHealth.state === 'degraded'} />

      <main className="grid gap-8">
        <GenerateSection
          isSubmitting={generation.isSubmitting}
          isApiReady={apiHealth.state === 'ok'}
          error={generation.error}
          onSubmit={generation.submit}
        />

        <GenerationProgress
          taskId={generation.taskId}
          status={generation.status}
          isPolling={generation.isPolling}
          error={generation.error}
          onReset={generation.reset}
        />

        <GallerySection
          items={gallery.items}
          page={gallery.page}
          pages={gallery.pages}
          total={gallery.total}
          isLoading={gallery.isLoading}
          error={gallery.error}
          onPageChange={gallery.setPage}
          onReload={gallery.reload}
          onVerifyImage={(imageUrl) => {
            void verifyGalleryImage(imageUrl)
          }}
        />

        <DecoderSection
          previewUrl={decoder.previewUrl}
          decodedText={decoder.decodedText}
          verification={decoder.verification}
          isVerifying={decoder.isVerifying}
          error={decoder.error}
          onFileSelect={decoder.selectFile}
          onVerify={decoder.verify}
          onReset={decoder.reset}
        />

        <PricingSection />
      </main>

      <AppFooter />

      {toast ? (
        <Toast message={toast.message} variant={toast.variant} onDismiss={() => setToast(null)} />
      ) : null}

      <WelcomeModal />
      <MobileNav />
      <KeyboardHelp />
    </div>
  )
}

export default App
