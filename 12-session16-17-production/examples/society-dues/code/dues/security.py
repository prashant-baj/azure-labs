"""Layer 6 security controls - each one answers a row of threat-model.md.

SEC-001  Spoofing:    a role header alone proved nothing (T-01). A caller with a role must also present the
                      treasurer key - a secret the app reads from its environment, never from a file.
SEC-002  Tampering /  Browsers get headers that refuse framing, sniffing and referrers (T-04, ZAP baseline).
         disclosure:
SEC-003  Injection:   anything written into HTML is escaped first (T-05).
"""

import hmac
import os

from fastapi import HTTPException
from starlette.middleware.base import BaseHTTPMiddleware

ALLOWED_ROLES = {"treasurer", "secretary"}  # C-002: only these may see who paid what

SECURITY_HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
    "Content-Security-Policy": "default-src 'self'; frame-ancestors 'none'; form-action 'self'",
    "Cache-Control": "no-store",
}


def require_role(role: str | None, key: str | None) -> None:
    """SEC-001 and C-002. Fail closed: no key configured means nobody gets in."""
    if role not in ALLOWED_ROLES:
        raise HTTPException(status_code=403, detail="Only the treasurer or the secretary may see this (C-002)")
    expected = os.getenv("TREASURER_KEY", "")
    if not expected:
        raise HTTPException(status_code=503, detail="Treasurer access is not configured (TREASURER_KEY)")
    if not key or not hmac.compare_digest(key.encode(), expected.encode()):  # constant time - no timing hints
        raise HTTPException(status_code=401, detail="A valid X-Api-Key is required")


class SecurityHeaders(BaseHTTPMiddleware):
    """SEC-002 - on every response, JSON and HTML alike."""

    async def dispatch(self, request, call_next):
        response = await call_next(request)
        for name, value in SECURITY_HEADERS.items():
            response.headers.setdefault(name, value)
        return response
