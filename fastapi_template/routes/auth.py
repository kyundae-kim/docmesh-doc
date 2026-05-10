from fastapi import APIRouter, Depends, Form
import logging

from fastapi_template.schemas import TokenResponse, UserInfo
from fastapi_template.dependencies.security import (
    get_current_user,
    require_permissions,
    require_roles,
    require_scopes,
    get_auth_provider,
    User,
)
from fastapi_template.services.security import authenticate, refresh_token

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/token", response_model=TokenResponse)
def get_token(username: str = Form(...), password: str = Form(...), provider=Depends(get_auth_provider)):
    logger.info("Post /token")
    logger.debug("Post /token username=%s", username)

    token_response = authenticate(provider=provider, username=username, password=password)

    logger.info("Post /token response")
    logger.debug("Post /token token_type=%s", token_response.token_type)
    return token_response


@router.get("/user", response_model=UserInfo, description="Get the current user's information for development purposes. This endpoint is not intended for production use.")
def user_info(current_user: User = Depends(get_current_user)):
    logger.info("Get /user")
    logger.debug("Get /user response ready")
    return current_user


@router.post("/example", dependencies=[Depends(require_roles("create"))], description="Example endpoint that requires 'create' role. This is for demonstration purposes.")
def example_create(current_user: User = Depends(get_current_user)):
    logger.info("Post /example")
    
    return {"message": "This is an example endpoint that requires 'create' role."}


@router.get("/example", dependencies=[Depends(require_roles("read"))], description="Example endpoint that requires 'read' role. This is for demonstration purposes.")
def example_read(current_user: User = Depends(get_current_user)):
    logger.info("Get /example")
    
    return {"message": "This is an example endpoint that requires 'read' role."}


@router.get("/example/scope", dependencies=[Depends(require_scopes("profile"))], description="Example endpoint that requires 'profile' scope. This is for demonstration purposes.")
def example_scope(current_user: User = Depends(get_current_user)):
    logger.info("Get /example/scope")

    return {"message": "This is an example endpoint that requires 'profile' scope."}


@router.delete("/example", dependencies=[Depends(require_roles("delete"))], description="Example endpoint that requires 'delete' role. This is for demonstration purposes.")
def example_delete(current_user: User = Depends(get_current_user)):
    logger.info("Delete /example")
    
    return {"message": "This is an example endpoint that requires 'delete' role."}
