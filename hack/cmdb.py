#!/usr/bin/env python3
"""Minimal mock CMDB API for testing the Ansible playbook."""

import argparse
import json
import random
import re
from http.server import BaseHTTPRequestHandler, HTTPServer


class CMDBHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    resources = set()

    def _read_request_body(self):
        length = int(self.headers.get("Content-Length", 0))
        if length:
            self.rfile.read(length)

    def _send_json(self, status, payload):
        body = (json.dumps(payload, indent=2) + "\n").encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(body)
        self.wfile.flush()
        print(f"[cmdb] {status} {self.command} {self.path} -> {payload}", flush=True)

    def _send_status(self, status):
        self.send_response(status)
        self.send_header("Connection", "close")
        self.end_headers()
        print(f"[cmdb] {status} {self.command} {self.path}", flush=True)

    def do_POST(self):
        self._read_request_body()

        path = self.path.rstrip("/") or "/"
        if path != "/vm/create":
            self.send_error(404, "Not Found")
            return

        resource_uuid = f"{random.randint(1000, 9999):04d}"
        self.resources.add(resource_uuid)
        self._send_json(201, {"resource_UUID": resource_uuid})

    def do_DELETE(self):
        self._read_request_body()

        match = re.fullmatch(r"/vm/([^/]+)", self.path.rstrip("/") or "/")
        if not match:
            self.send_error(404, "Not Found")
            return

        resource_uuid = match.group(1)
        self.resources.discard(resource_uuid)
        self._send_status(200)

    def log_message(self, format, *args):
        print(f"[cmdb] {self.address_string()} - {format % args}", flush=True)


def main():
    parser = argparse.ArgumentParser(description="Mock CMDB API")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()

    server = HTTPServer((args.host, args.port), CMDBHandler)
    base_url = f"http://{args.host}:{args.port}"
    print(f"Mock CMDB listening on {base_url}", flush=True)
    print(f"Test create: curl -s -X POST {base_url}/vm/create", flush=True)
    print(f"Test delete: curl -s -o /dev/null -w '%{{http_code}}\\n' -X DELETE {base_url}/vm/1234", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.", flush=True)
        server.server_close()


if __name__ == "__main__":
    main()
