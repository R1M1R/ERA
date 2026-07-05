/** Pipeline step identifiers shared by backend workers and the frontend UI. */

export const PIPELINE_STEP_IDS = ['generate_riddle', 'encode_artifact', 'persist_metadata'] as const

export function getStepIndex(stepId?: string | null): number {
  if (!stepId) {
    return -1
  }
  const index = PIPELINE_STEP_IDS.indexOf(stepId as (typeof PIPELINE_STEP_IDS)[number])
  return index >= 0 ? index : PIPELINE_STEP_IDS.length - 1
}
