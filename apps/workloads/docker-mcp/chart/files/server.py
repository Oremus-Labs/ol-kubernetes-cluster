import os
from contextlib import asynccontextmanager

from docker_mcp.server import server as docker_mcp_server
from mcp.server.streamable_http_manager import StreamableHTTPSessionManager
from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Mount, Route

session_manager = StreamableHTTPSessionManager(
    docker_mcp_server,
    stateless=True,
)


@asynccontextmanager
def lifespan(app):
    async with session_manager.run():
        yield


def make_healthz_response(_request):
    return JSONResponse({"status": "ok"})


class MCPApplication:
    async def __call__(self, scope, receive, send):
        await session_manager.handle_request(scope, receive, send)


mcp_app = MCPApplication()

app = Starlette(
    lifespan=lifespan,
    routes=[
        Mount("/mcp", app=mcp_app),
    ],
)

app.add_route("/healthz", make_healthz_response, methods=["GET"])


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
