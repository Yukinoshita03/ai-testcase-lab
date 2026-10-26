from fastapi import APIRouter

from services import product_service


router = APIRouter(prefix="/product", tags=["products"])


@router.get("")
def list_products():
    return product_service.list_products()
