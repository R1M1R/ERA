import type { PipelineStep } from '../types/api'

export const PIPELINE_STEPS: PipelineStep[] = [
  {
    id: 'generate_riddle',
    label: 'LLM riddle synthesis',
    description: 'Autonomous historical riddle generation via the AI orchestrator.',
  },
  {
    id: 'encode_artifact',
    label: 'Steganographic seal',
    description: 'Embed the riddle into a procedural pixel artifact via LSB.',
  },
  {
    id: 'persist_metadata',
    label: 'Archive persistence',
    description: 'Store the artifact record in PostgreSQL for the public gallery.',
  },
]

export function getStepIndex(stepId?: string | null): number {
  if (!stepId) {
    return -1
  }

  const index = PIPELINE_STEPS.findIndex((step) => step.id === stepId)
  return index >= 0 ? index : PIPELINE_STEPS.length - 1
}
