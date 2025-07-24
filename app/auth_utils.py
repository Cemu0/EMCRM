from fastapi import Request, Depends
from typing import Optional
from app.config import settings

def get_current_user_optional(request: Request) -> Optional[dict]:
    """Get current authenticated user from request state (optional)"""
    if not settings.auth.enabled:
        return None
    return getattr(request.state, 'user', None)

def get_current_user_required(request: Request) -> dict:
    """Get current authenticated user from request state (required)"""
    if not settings.auth.enabled:
        # Return a default user for development mode
        return {
            'user_id': 'dev-user',
            'username': 'developer',
            'email': 'dev@example.com',
            'groups': ['admin']
        }
    
    user = getattr(request.state, 'user', None)
    if not user:
        from fastapi import HTTPException, status
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required"
        )
    return user

# Convenience dependencies
OptionalAuth = Depends(get_current_user_optional)
RequiredAuth = Depends(get_current_user_required)