from fastapi import APIRouter


router = APIRouter(tags=["health"])


@router.get("/health")
def check_health():
    return {"status": "ok"}
