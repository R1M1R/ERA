from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

from celery.result import AsyncResult
from dotenv import load_dotenv
from fastapi import FastAPI, File, Header, HTTPException, Query, Request, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, Response

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")
load_dotenv()

from backend.celery_client import celery_app
from config import get_cors_origins
from database import init_database
from repository import get_artifact_by_public_hash, list_artifacts
from schemas import (
    ArtifactListResponse,
    GenerateResponse,
    ProActivateRequest,
    ProActivateResponse,
    ProStatusResponse,
    TaskStatusResponse,
    VerifyResponse,
)
from verify_service import verify_artifact_image
from health_service import collect_health_status
from pro_service import (
    activate_pro_by_email,
    get_pro_status,
    handle_lemon_webhook_event,
    is_pro_license_active,
    should_use_pro_llm,
    verify_lemon_signature,
)


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

CORS_ORIGINS = get_cors_origins()

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
    return await collect_health_status()


@app.post("/generate", response_model=GenerateResponse, status_code=status.HTTP_202_ACCEPTED)
async def generate_artifact(
    x_era_pro_key: str | None = Header(default=None, alias="X-ERA-Pro-Key"),
) -> GenerateResponse:
    """Queue autonomous LLM riddle generation and steganographic artifact creation."""
    from worker.tasks import enqueue_generation_pipeline

    pro_key = x_era_pro_key.strip() if x_era_pro_key else None
    pro_tier = await should_use_pro_llm(pro_key)
    has_license = await is_pro_license_active(pro_key) if pro_key else False

    task_id = enqueue_generation_pipeline(pro_tier=pro_tier)
    return GenerateResponse(task_id=task_id, tier="pro" if has_license else "demo")


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
    if artifact.image_bytes:
        return Response(
            content=artifact.image_bytes,
            media_type="image/png",
            headers={"Content-Disposition": f'inline; filename="era-{public_hash}.png"'},
        )

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


@app.get("/pro/status", response_model=ProStatusResponse)
async def pro_status(
    x_era_pro_key: str | None = Header(default=None, alias="X-ERA-Pro-Key"),
) -> ProStatusResponse:
    """Return whether the provided Pro API key is active."""
    payload = await get_pro_status(x_era_pro_key.strip() if x_era_pro_key else None)
    return ProStatusResponse(**payload)


@app.post("/pro/activate", response_model=ProActivateResponse)
async def pro_activate(body: ProActivateRequest) -> ProActivateResponse:
    """Return the Pro API key for an active Lemon Squeezy subscription email."""
    try:
        payload = await activate_pro_by_email(body.email)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    except LookupError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc

    return ProActivateResponse(**payload)


@app.post("/webhooks/lemonsqueezy")
async def lemon_squeezy_webhook(request: Request) -> dict[str, str]:
    """Handle Lemon Squeezy subscription lifecycle events."""
    import json

    body = await request.body()
    signature = request.headers.get("X-Signature")
    if not verify_lemon_signature(body, signature):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid webhook signature.")

    try:
        payload = json.loads(body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid JSON payload.") from exc

    event_name = str((payload.get("meta") or {}).get("event_name") or "").strip()
    if not event_name:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Missing event_name.")

    return handle_lemon_webhook_event(event_name, payload)
