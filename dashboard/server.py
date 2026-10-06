"""
dashboard/server.py
Interactive DevSecOps Cyber Command Center Development Server
Proxies all requests directly to the AWS-Native API Gateway backend.
Zero local PowerShell or laptop script execution dependencies.
Author: sathvik-devsecops
"""
import os
import sys
import json
import time
import urllib.request
import urllib.parse
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

PORT = 8080
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
API_GATEWAY_URL = "https://gq4mp9mxwc.execute-api.us-east-1.amazonaws.com"

class DevSecOpsDashboardHandler(BaseHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type,Authorization")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        parsed_url = urllib.parse.urlparse(self.path)
        path = parsed_url.path

        if path == "/" or path == "/index.html":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            with open(os.path.join(os.path.dirname(__file__), "index.html"), "rb") as f:
                self.wfile.write(f.read())
            return

        elif path.startswith("/evidence/"):
            # Serve local evidence screenshots if available, or redirect
            rel_path = path.lstrip("/")
            full_path = os.path.join(BASE_DIR, rel_path)
            if os.path.exists(full_path) and os.path.isfile(full_path):
                self.send_response(200)
                if full_path.endswith(".png"):
                    self.send_header("Content-Type", "image/png")
                elif full_path.endswith(".txt") or full_path.endswith(".md"):
                    self.send_header("Content-Type", "text/plain; charset=utf-8")
                self.end_headers()
                with open(full_path, "rb") as f:
                    self.wfile.write(f.read())
                return
            else:
                self.send_error(404, "Evidence File Not Found")
                return

        elif path.startswith("/api/"):
            # Proxy request to live AWS API Gateway
            self.proxy_to_aws_api("GET", path)
            return

        else:
            self.send_error(404, "Not Found")

    def do_POST(self):
        parsed_url = urllib.parse.urlparse(self.path)
        path = parsed_url.path

        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b"{}"

        if path.startswith("/api/"):
            self.proxy_to_aws_api("POST", path, body)
            return
        else:
            self.send_error(404, "Not Found")

    def proxy_to_aws_api(self, method, path, body=None):
        """Forwards request to AWS Cloud API Gateway and streams response back"""
        target_url = f"{API_GATEWAY_URL}{path}"
        try:
            req = urllib.request.Request(target_url, data=body if method == "POST" else None, method=method)
            req.add_header("Content-Type", "application/json")
            with urllib.request.urlopen(req, timeout=30) as resp:
                resp_data = resp.read()
                self.send_response(resp.status)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(resp_data)
        except urllib.error.HTTPError as e:
            err_data = e.read()
            self.send_response(e.code)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(err_data)
        except Exception as e:
            self.send_response(500)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e), "targetUrl": target_url}).encode("utf-8"))

def run_server():
    server_address = ("", PORT)
    httpd = ThreadingHTTPServer(server_address, DevSecOpsDashboardHandler)
    print(f"============================================================")
    print(f" SATHVIK DEVSECOPS COMMAND CENTER (LOCAL PROXY RUNNER)       ")
    print(f" Web UI:       http://localhost:{PORT}                       ")
    print(f" AWS Backend:  {API_GATEWAY_URL}                             ")
    print(f" Target Cloud: AWS Account 009160054307 (us-east-1)          ")
    print(f" Execution:    100% AWS Cloud Native (Zero Local PowerShell) ")
    print(f"============================================================")
    httpd.serve_forever()

if __name__ == "__main__":
    run_server()
