import os
from typing import AsyncIterator

import httpx
from fastapi import FastAPI, Request, Response, status
from fastapi.responses import StreamingResponse, JSONResponse

UPSTREAM_URL = os.getenv("UPSTREAM_URL", "https://api.githubcopilot.com/mcp/")
TOKEN = os.getenv("GITHUB_PERSONAL_ACCESS_TOKEN")
VERIFY_TLS = os.getenv("UPSTREAM_VERIFY_TLS", "true").lower() != "false"

if not TOKEN:
    raise RuntimeError("GITHUB_PERSONAL_ACCESS_TOKEN must be set")

app = FastAPI()
client = httpx.AsyncClient(verify=VERIFY_TLS, timeout=None)


def _filtered_headers(request: Request) -> dict[str, str]:
    skip = {"host", "content-length", "connection"}
    headers = {
        key: value
        for key, value in request.headers.items()
        if key.lower() not in skip
    }
    headers["Authorization"] = f"Bearer {TOKEN}"
    return headers


async def _proxy_stream(request: Request, method: str) -> StreamingResponse:
    headers = _filtered_headers(request)
    upstream = f"{UPSTREAM_URL.rstrip('/')}/"
    params = request.query_params.multi_items()
    stream = client.stream
    upstream_request = stream(method, upstream, headers=headers, params=params)

    async with upstream_request as upstream_response:
        async def generator() -> AsyncIterator[bytes]:
            async for chunk in upstream_response.aiter_raw():
                yield chunk

        forwarded_headers = {
            k: v for k, v in upstream_response.headers.items() if k.lower() != "content-length"
        }
        return StreamingResponse(
            generator(),
            status_code=upstream_response.status_code,
            media_type=upstream_response.headers.get("content-type", "text/event-stream"),
            headers=forwarded_headers,
        )


async def _proxy_request(request: Request, method: str) -> Response:
    headers = _filtered_headers(request)
    body = await request.body()
    upstream = f"{UPSTREAM_URL.rstrip('/')}/"
    resp = await client.request(method, upstream, content=body, headers=headers, params=request.query_params)
    forwarded_headers = {
        k: v for k, v in resp.headers.items() if k.lower() != "content-length"
    }
    return Response(content=resp.content, status_code=resp.status_code, headers=forwarded_headers)


@app.api_route("/mcp", methods=["GET", "POST", "DELETE"])
async def handle(request: Request):
    if request.method == "GET":
        return await _proxy_stream(request, "GET")
    return await _proxy_request(request, request.method)


@app.get("/healthz")
async def health() -> JSONResponse:
    return JSONResponse({"status": "ok"}, status_code=status.HTTP_200_OK)
