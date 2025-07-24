from fastapi import APIRouter, HTTPException, status, Depends, Request, Response
from fastapi.responses import RedirectResponse, JSONResponse
from pydantic import BaseModel
from typing import Optional
import logging
import json
from datetime import datetime, timedelta
from itsdangerous import URLSafeTimedSerializer
from authlib.integrations.requests_client import OAuth2Session
from app.config import settings

logger = logging.getLogger(__name__)
router = APIRouter()

# Session management for testing
SECRET_KEY = settings.auth.cognito_client_secret or "dev-secret-key-for-testing"
serializer = URLSafeTimedSerializer(SECRET_KEY)

def set_auth_cookie(response: Response, token_data: dict, user_info: Optional[dict] = None):
    """Set secure authentication cookies for testing"""
    auth_data = {
        "access_token": token_data.get("access_token"),
        "refresh_token": token_data.get("refresh_token"),
        "token_type": token_data.get("token_type", "bearer"),
        "expires_in": token_data.get("expires_in", 3600),
        "timestamp": datetime.now().isoformat(),
        "user_info": user_info
    }
    
    # Serialize and set cookie
    cookie_value = serializer.dumps(auth_data)
    response.set_cookie(
        key="auth_session",
        value=cookie_value.decode('utf-8') if isinstance(cookie_value, bytes) else cookie_value,
        max_age=token_data.get("expires_in", 3600),
        httponly=True,
        secure=False,  # Set to True in production with HTTPS
        samesite="lax"
    )
    
def get_auth_from_cookie(request: Request) -> Optional[dict]:
    """Get authentication data from cookie"""
    cookie_value = request.cookies.get("auth_session")
    if not cookie_value:
        return None
    
    try:
        auth_data = serializer.loads(cookie_value, max_age=3600)  # 1 hour max
        return auth_data
    except Exception as e:
        logger.warning(f"Invalid auth cookie: {e}")
        return None

def clear_auth_cookie(response: Response):
    """Clear authentication cookie"""
    response.delete_cookie(key="auth_session")

# Pydantic models
class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    refresh_token: Optional[str] = None

class UserInfo(BaseModel):
    user_id: str
    username: str
    email: Optional[str] = None
    groups: list = []

# OAuth2 client setup
def create_oauth_client() -> OAuth2Session:
    """Create OAuth2 client for Cognito"""
    return OAuth2Session(
        client_id=settings.auth.cognito_client_id,
        client_secret=getattr(settings.auth, 'cognito_client_secret', None),
        scope='email openid phone profile'
    )

def get_cognito_config():
    """Get Cognito configuration"""
    base_url = f"https://{settings.auth.cognito_user_pool_id}.auth.{settings.auth.cognito_region}.amazoncognito.com"
    return {
        'authorization_endpoint': f"{base_url}/login",
        'token_endpoint': f"{base_url}/oauth2/token",
        'userinfo_endpoint': f"{base_url}/oauth2/userInfo",
        'metadata_url': f"https://cognito-idp.{settings.auth.cognito_region}.amazonaws.com/{settings.auth.cognito_user_pool_id}/.well-known/openid-configuration"
    }

# Dependency to get current user from request state
def get_current_user(request: Request) -> Optional[dict]:
    """Get current user from request state (set by auth middleware) or cookie"""
    # First try to get from middleware (JWT validation)
    user = getattr(request.state, 'user', None)
    if user:
        return user
    
    # Fallback to cookie-based session for testing
    auth_data = get_auth_from_cookie(request)
    if auth_data and auth_data.get('user_info'):
        return auth_data['user_info']
    
    return None

@router.get("/login")
async def login(redirect_uri: Optional[str] = None):
    """Redirect to Cognito for authentication visit http://localhost:8080/auth/login to login"""
    redirect_uri = redirect_uri or "http://localhost:8080/auth/callback"
    
    try:
        client = create_oauth_client()
        client.redirect_uri = redirect_uri
        
        config = get_cognito_config()
        authorization_url, state = client.create_authorization_url(
            config['authorization_endpoint']
        )
        
        logger.info("Redirecting to Cognito login")
        return RedirectResponse(url=authorization_url, status_code=302)
        
    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Authentication service error"
        )

@router.get("/callback")
async def auth_callback(response: Response, code: Optional[str] = None, error: Optional[str] = None, state: Optional[str] = None):
    """Handle OAuth callback from Cognito"""
    if error:
        raise HTTPException(status_code=400, detail=f"Authentication failed: {error}")
    if not code:
        raise HTTPException(status_code=400, detail="Authorization code not provided")
    
    try:
        client = create_oauth_client()
        client.redirect_uri = "http://localhost:8080/auth/callback"
        
        config = get_cognito_config()
        token = client.fetch_token(
            config['token_endpoint'],
            authorization_response=f"http://localhost:8080/auth/callback?code={code}&state={state or ''}"
        )
        
        # Fetch user info
        user_info = None
        try:
            client.token = token
            user_response = client.get(config['userinfo_endpoint'])
            if user_response.status_code == 200:
                user_info = user_response.json()
                logger.info(f"User info retrieved: {user_info.get('email', 'unknown')}")
        except Exception as e:
            logger.warning(f"Failed to fetch user info: {e}")
        
        # Save authentication data in cookie for testing
        set_auth_cookie(response, token, user_info)
        
        logger.info("Token exchange successful and saved to cookie")
        return {
            "message": "Authentication successful",
            "user_info": user_info,
            "token_saved": True,
            "expires_in": token.get('expires_in', 3600)
        }
        
    except Exception as e:
        logger.error(f"Token exchange error: {str(e)}")
        raise HTTPException(status_code=500, detail="Authentication service error")

@router.get("/userinfo")
async def get_userinfo(access_token: str):
    """Get user information from access token"""
    try:
        client = OAuth2Session()
        config = get_cognito_config()
        
        response = client.get(
            config['userinfo_endpoint'],
            headers={'Authorization': f'Bearer {access_token}'}
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            raise HTTPException(status_code=401, detail="Invalid token")
            
    except Exception as e:
        logger.error(f"Userinfo error: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid token")

@router.post("/refresh")
async def refresh_token(refresh_token: str):
    """Refresh access token"""
    try:
        client = create_oauth_client()
        config = get_cognito_config()
        
        new_token = client.refresh_token(
            config['token_endpoint'],
            refresh_token=refresh_token
        )
        
        return TokenResponse(
            access_token=new_token['access_token'],
            expires_in=new_token.get('expires_in', 3600),
            refresh_token=new_token.get('refresh_token', refresh_token)
        )
        
    except Exception as e:
        logger.error(f"Token refresh error: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid refresh token")

@router.get("/me", response_model=UserInfo)
async def get_current_user_info(current_user: dict = Depends(get_current_user)):
    """Get current user information"""
    if not current_user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    return UserInfo(
        user_id=current_user.get('user_id', ''),
        username=current_user.get('username', ''),
        email=current_user.get('email'),
        groups=current_user.get('groups', [])
    )

@router.get("/session")
async def get_session(request: Request):
    """Get current session data from cookie"""
    auth_data = get_auth_from_cookie(request)
    if not auth_data:
        raise HTTPException(status_code=401, detail="No active session")
    
    return {
        "authenticated": True,
        "user_info": auth_data.get("user_info"),
        "token_type": auth_data.get("token_type"),
        "expires_in": auth_data.get("expires_in"),
        "timestamp": auth_data.get("timestamp")
    }

@router.get("/token")
async def get_access_token(request: Request):
    """Get access token for API calls (testing only)"""
    auth_data = get_auth_from_cookie(request)
    if not auth_data:
        raise HTTPException(status_code=401, detail="No active session")
    
    return {
        "access_token": auth_data.get("access_token"),
        "token_type": auth_data.get("token_type", "bearer"),
        "expires_in": auth_data.get("expires_in")
    }

@router.post("/logout")
async def logout(response: Response):
    """Logout user and clear session"""
    clear_auth_cookie(response)
    return {"message": "Logged out successfully"}

@router.get("/status")
async def auth_status():
    """Get authentication status"""
    return {
        "authentication_enabled": settings.auth.enabled,
        "cognito_configured": bool(settings.auth.cognito_user_pool_id and settings.auth.cognito_client_id),
        "region": settings.auth.cognito_region
    }