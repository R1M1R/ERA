import type {
  ArtifactListResponse,
  GenerateResponse,
  TaskStatusResponse,
  VerifyResponse,
} from '../types/api'

const API_BASE_URL =
  import.meta.env.VITE_API_URL ??
  (import.meta.env.DEV ? '' : 'https://era-api.onrender.com')

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const isFormData = init?.body instanceof FormData
  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: {
      ...(isFormData ? {} : { 'Content-Type': 'application/json' }),
      ...(init?.headers ?? {}),
    },
    ...init,
  })

  if (!response.ok) {
    const detail = await response.text()
    throw new Error(detail || `Request failed with status ${response.status}`)
  }

  return response.json() as Promise<T>
}

export async function submitGeneration(): Promise<GenerateResponse> {
  return request<GenerateResponse>('/generate', {
    method: 'POST',
  })
}

export async function fetchTaskStatus(taskId: string): Promise<TaskStatusResponse> {
  return request<TaskStatusResponse>(`/status/${taskId}`)
}

export async function fetchArtifacts(page = 1, pageSize = 12): Promise<ArtifactListResponse> {
  const params = new URLSearchParams({
    page: String(page),
    page_size: String(pageSize),
  })
  return request<ArtifactListResponse>(`/artifacts?${params.toString()}`)
}

export async function verifyArtifact(file: File): Promise<VerifyResponse> {
  const formData = new FormData()
  formData.append('file', file)

  return request<VerifyResponse>('/verify', {
    method: 'POST',
    body: formData,
  })
}

export function getApiBaseUrl(): string {
  return API_BASE_URL
}

export function isHostedFrontend(): boolean {
  if (import.meta.env.DEV) return false
  try {
    const host = window.location.hostname
    return host !== 'localhost' && host !== '127.0.0.1'
  } catch {
    return false
  }
}

export function resolveArtifactImageUrl(imageUrl: string): string {
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return imageUrl
  }
  return `${API_BASE_URL}${imageUrl}`
}
