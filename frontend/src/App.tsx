import { useCallback, useState } from 'react'

import { GenerateSection } from './components/GenerateSection'
import { AppHeader } from './components/AppHeader'
import { DecoderSection } from './components/DecoderSection'
import { GallerySection } from './components/GallerySection'
import { GenerationProgress } from './components/GenerationProgress'
import { useArtifacts } from './hooks/useArtifacts'
import { useDecoder } from './hooks/useDecoder'
import { useApiHealth } from './hooks/useApiHealth'
import { useGeneration } from './hooks/useGeneration'
import { resolveArtifactImageUrl } from './lib/api'

function App() {
  const [galleryRefreshKey, setGalleryRefreshKey] = useState(0)
  const refreshGallery = useCallback(() => {
    setGalleryRefreshKey((value) => value + 1)
  }, [])

  const generation = useGeneration(refreshGallery)
  const gallery = useArtifacts({ refreshKey: galleryRefreshKey })
  const decoder = useDecoder()
  const apiHealth = useApiHealth()

  const verifyGalleryImage = useCallback(
    async (imageUrl: string) => {
      const response = await fetch(resolveArtifactImageUrl(imageUrl))
      if (!response.ok) {
        throw new Error('Failed to load artifact image.')
      }
      const blob = await response.blob()
      const file = new File([blob], 'era-artifact.png', { type: blob.type || 'image/png' })
      decoder.selectFile(file)
      document.getElementById('decoder-section')?.scrollIntoView({ behavior: 'smooth', block: 'start' })
    },
    [decoder],
  )

  return (
    <div className="mx-auto min-h-screen max-w-6xl px-4 py-10 sm:px-6 lg:px-8">
      <AppHeader />

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
      </main>
    </div>
  )
}

export default App
