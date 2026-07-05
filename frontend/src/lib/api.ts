import type {
  ArtifactListResponse,
  GenerateResponse,
  HealthResponse,
  ProActivateResponse,
  ProStatusResponse,
  TaskStatusResponse,
  VerifyResponse,
} from '../types/api'
import { getProKey } from './proKey'
import { parseApiError } from './apiError'

const API_BASE_URL = import.meta.env.VITE_API_URL ?? ''
const REQUEST_TIMEOUT_MS = 30_000

function proHeaders(): HeadersInit {
  const key = getProKey()
  return key ? { 'X-ERA-Pro-Key': key } : {}
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const isFormData = init?.body instanceof FormData
  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: {
      ...(isFormData ? {} : { 'Content-Type': 'application/json' }),
      ...(init?.headers ?? {}),
    },
    signal: init?.signal ?? AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    ...init,
  })

  if (!response.ok) {
    throw new Error(await parseApiError(response))
  }

  return response.json() as Promise<T>
}

export async function fetchHealth(): Promise<HealthResponse> {
  return request<HealthResponse>('/health')
}

export async function submitGeneration(): Promise<GenerateResponse> {
  return request<GenerateResponse>('/generate', {
    method: 'POST',
    headers: proHeaders(),
  })
}

export async function fetchProStatus(): Promise<ProStatusResponse> {
  return request<ProStatusResponse>('/pro/status', {
    headers: proHeaders(),
  })
}

export async function activateProByEmail(email: string): Promise<ProActivateResponse> {
  return request<ProActivateResponse>('/pro/activate', {
    method: 'POST',
    body: JSON.stringify({ email }),
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
