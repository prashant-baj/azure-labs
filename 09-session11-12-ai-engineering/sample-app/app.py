"""A tiny stand-in app for the deploy exercise - use it only if your own component cannot run in a container yet.
Standard library only. GET /health and GET / answer; nothing else."""
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

VERSION = os.environ.get("APP_VERSION", "v1")
PORT = int(os.environ.get("PORT", "8000"))


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):  # noqa: N802 - the name http.server expects
        if self.path == "/health":
            self._reply(200, {"status": "ok", "version": VERSION})
        elif self.path == "/":
            self._reply(200, {"app": "sample-app", "version": VERSION, "try": "/health"})
        else:
            self._reply(404, {"error": "not found"})

    def _reply(self, code, body):
        data = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):  # one line per request, no request bodies
        print(f"{self.command} {self.path} -> {args[1] if len(args) > 1 else ''}", flush=True)


if __name__ == "__main__":
    print(f"sample-app {VERSION} listening on {PORT}", flush=True)
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
