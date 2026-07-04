export type TaskStatus = 'queued' | 'running' | 'completed' | 'failed'

export interface GenerateResponse {
  task_id: string
  status: 'queued'
  mode?: 'autonomous'
}

export interface GenerationResult {
  task_id: string
  riddle?: string
  answer?: string
  embedded_text?: string
  status: string
  image_path?: string
  image_base64?: string
  database_record?: ArtifactItem
}

export interface TaskStatusResponse {
  task_id: string
  status: TaskStatus
  step?: string | null
  result?: GenerationResult | null
  error?: string | null
}

export interface PipelineStep {
  id: string
  label: string
  description: string
}

export interface ArtifactItem {
  id: number
  public_hash: string
  image_url: string
  created_at: string
  is_solved: boolean
}

export interface ArtifactListResponse {
  items: ArtifactItem[]
  total: number
  page: number
  page_size: number
  pages: number
}

export interface VerifyResponse {
  status: 'authentic' | 'fake'
  message: string
  verified: boolean
  text?: string | null
  authenticity_hash?: string | null
  detail?: string | null
}
