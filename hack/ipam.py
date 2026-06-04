#!/usr/bin/env python3
"""Minimal mock IPAM API for testing the Ansible playbook."""

import argparse
import json
import random
from http.server import BaseHTTPRequestHandler, HTTPServer


class IPAMHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

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
        print(f"[ipam] {status} {self.command} {self.path} -> {payload}", flush=True)

    def _random_ip(self):
        host = random.randint(1, 254)
        return f"192.168.1.{host}"

    def do_POST(self):
        self._read_request_body()

        path = self.path.rstrip("/") or "/"
        if path != "/ip/request":
            self.send_error(404, "Not Found")
            return

        ip_address = self._random_ip()
        self._send_json(201, {"ip address": ip_address})

    def log_message(self, format, *args):
        print(f"[ipam] {self.address_string()} - {format % args}", flush=True)


def main():
    parser = argparse.ArgumentParser(description="Mock IPAM API")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8081)
    args = parser.parse_args()

    server = HTTPServer((args.host, args.port), IPAMHandler)
    base_url = f"http://{args.host}:{args.port}"
    print(f"Mock IPAM listening on {base_url}", flush=True)
    print(f"Subnet: 192.168.1.0/24", flush=True)
    print(f"Test: curl -s -X POST {base_url}/ip/request", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.", flush=True)
        server.server_close()


if __name__ == "__main__":
    main()
