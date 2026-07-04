from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

from celery.result import AsyncResult
from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, Query, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from celery_client import celery_app
from database import init_database
from repository import get_artifact_by_public_hash, list_artifacts
from schemas import ArtifactListResponse, GenerateResponse, TaskStatusResponse, VerifyResponse
from verify_service import verify_artifact_image

load_dotenv()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_database()
    yield


app = FastAPI(
    title="ERA — Steganographic Historical Artifacts",
    description="SaaS API for generating steganographic historical artifacts",
    version="0.4.0",
    lifespan=lifespan,
)

CORS_ORIGINS = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "http://localhost:4173",
    "http://127.0.0.1:4173",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _map_celery_state(async_result: AsyncResult) -> TaskStatusResponse:
    """Translate Celery AsyncResult into an API-friendly status object."""
    state = async_result.state
    meta = async_result.info if isinstance(async_result.info, dict) else {}
    step = meta.get("step") if isinstance(meta, dict) else None

    if state == "PENDING":
        return TaskStatusResponse(task_id=async_result.id, status="queued")

    if state in {"STARTED", "PROGRESS"}:
        return TaskStatusResponse(task_id=async_result.id, status="running", step=step)

    if state == "SUCCESS":
        result = async_result.result if isinstance(async_result.result, dict) else {"value": async_result.result}
        return TaskStatusResponse(task_id=async_result.id, status="completed", result=result)

    if state == "FAILURE":
        error = str(async_result.result) if async_result.result is not None else "Unknown worker failure"
        return TaskStatusResponse(task_id=async_result.id, status="failed", error=error)

    return TaskStatusResponse(task_id=async_result.id, status="running", step=state.lower())


@app.get("/")
async def root() -> dict[str, str]:
    return {"message": "ERA API is running"}


@app.get("/health")
async def health() -> dict[str, Any]:
    return {"status": "ok", "service": "era-api", "version": "0.4.0"}


@app.post("/generate", response_model=GenerateResponse, status_code=status.HTTP_202_ACCEPTED)
async def generate_artifact() -> GenerateResponse:
    """Queue autonomous LLM riddle generation and steganographic artifact creation."""
    from worker.tasks import enqueue_generation_pipeline

    task_id = enqueue_generation_pipeline()
    return GenerateResponse(task_id=task_id)


@app.get("/status/{task_id}", response_model=TaskStatusResponse)
async def get_generation_status(task_id: str) -> TaskStatusResponse:
    """Return the current status and result of a generation job."""
    async_result = AsyncResult(task_id, app=celery_app)
    return _map_celery_state(async_result)


@app.get("/artifacts", response_model=ArtifactListResponse)
async def get_artifacts(
    page: int = Query(1, ge=1, description="Page number starting from 1."),
    page_size: int = Query(12, ge=1, le=100, description="Number of artifacts per page."),
) -> ArtifactListResponse:
    """Return the latest generated artifacts with pagination."""
    payload = await list_artifacts(page=page, page_size=page_size)
    return ArtifactListResponse(**payload)


@app.get("/artifacts/{public_hash}/image")
async def get_artifact_image(public_hash: str) -> FileResponse:
    """Serve the PNG file associated with a public artifact hash."""
    artifact = await get_artifact_by_public_hash(public_hash)
    if artifact is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Artifact not found.")

    image_path = Path(artifact.image_path)
    if not image_path.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Artifact image file is missing.")

    return FileResponse(image_path, media_type="image/png", filename=f"era-{public_hash}.png")


@app.post("/verify", response_model=VerifyResponse)
async def verify_artifact(file: UploadFile = File(...)) -> VerifyResponse:
    """Verify proof-of-authenticity for an uploaded artifact image."""
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only image uploads are supported.",
        )

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty.",
        )

    result = await verify_artifact_image(image_bytes)
    return VerifyResponse(**result)
