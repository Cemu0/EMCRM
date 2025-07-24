from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
import jwt
from jwt import PyJWKClient
import requests
from typing import Optional
import logging
from itsdangerous import URLSafeTimedSerializer
from app.config import settings

logger = logging.getLogger(__name__)

class AuthMiddleware(BaseHTTPMiddleware):
    """Authentication middleware for JWT token validation"""
    
    def __init__(self, app):
        super().__init__(app)
        self.public_paths = {
            "/docs",
            "/redoc", 
            "/openapi.json",
            "/health",
            "/auth/login",
            "/auth/logout",
            "/auth/callback",
            "/auth/status",
            "/auth/userinfo",
            "/auth/session",
            "/auth/token"
        }
        self.jwks_cache = None
        self.jwks_url = f"https://cognito-idp.{settings.auth.cognito_region}.amazonaws.com/{settings.auth.cognito_user_pool_id}/.well-known/jwks.json"
        # Cookie session support
        self.secret_key = settings.auth.cognito_client_secret or "dev-secret-key-for-testing"
        self.serializer = URLSafeTimedSerializer(self.secret_key)
    
    async def dispatch(self, request: Request, call_next):
        # Skip authentication for public paths
        if any(request.url.path.startswith(path) for path in self.public_paths):
            return await call_next(request)
        
        user_info = None
        
        # First try Authorization header (JWT token)
        authorization = request.headers.get("Authorization")
        if authorization and authorization.startswith("Bearer "):
            token = authorization.split(" ")[1]
            try:
                user_info = await self.validate_token(token)
            except Exception as e:
                logger.error(f"JWT validation error: {str(e)}")
        
        # If no JWT token or invalid, try cookie session
        if not user_info:
            user_info = self.get_user_from_cookie(request)
        
        # If still no user info, return unauthorized
        if not user_info:
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={"detail": "Missing or invalid authorization header"}
            )
        
        # Add user info to request state
        request.state.user = user_info
        
        return await call_next(request)
    
    def get_user_from_cookie(self, request: Request) -> Optional[dict]:
        """Get user info from cookie session"""
        cookie_value = request.cookies.get("auth_session")
        if not cookie_value:
            return None
        
        try:
            auth_data = self.serializer.loads(cookie_value, max_age=3600)  # 1 hour max
            user_info = auth_data.get("user_info")
            if user_info:
                logger.info(f"Cookie authentication successful for user: {user_info.get('email', 'unknown')}")
                return user_info
        except Exception as e:
            logger.warning(f"Invalid auth cookie: {e}")
        
        return None
    
    async def validate_token(self, token: str) -> Optional[dict]:
        """Validate JWT token against Cognito"""
        try:
            # Get JWKS if not cached
            if not self.jwks_cache:
                response = requests.get(self.jwks_url)
                response.raise_for_status()
                self.jwks_cache = response.json()
            
            # Decode token header to get key ID
            unverified_header = jwt.get_unverified_header(token)
            kid = unverified_header.get('kid')
            
            # Find the correct key
            key = None
            for jwk in self.jwks_cache['keys']:
                if jwk['kid'] == kid:
                    # Use PyJWKClient to handle the key conversion
                    from jwt.algorithms import RSAAlgorithm
                    key = RSAAlgorithm.from_jwk(jwk)
                    break
            
            if not key:
                logger.error("Unable to find appropriate key")
                return None
            
            # Verify and decode token
            payload = jwt.decode(
                token,
                key,
                algorithms=[settings.auth.jwt_algorithm],
                audience=settings.auth.cognito_client_id,
                issuer=f"https://cognito-idp.{settings.auth.cognito_region}.amazonaws.com/{settings.auth.cognito_user_pool_id}"
            )
            
            return {
                'user_id': payload.get('sub'),
                'username': payload.get('cognito:username'),
                'email': payload.get('email'),
                'groups': payload.get('cognito:groups', []),
                'token_use': payload.get('token_use')
            }
            
        except jwt.ExpiredSignatureError:
            logger.error("Token has expired")
            return None
        except jwt.InvalidTokenError as e:
            logger.error(f"Invalid token: {str(e)}")
            return None
        except Exception as e:
            logger.error(f"Token validation error: {str(e)}")
            return None