import os
from functools import partial
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import urlparse

from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / ".env")

folder = ROOT / (os.getenv("Data_filder") or "data/raw")
port = urlparse(os.getenv("FILES_URL", "")).port or 8001

handler = partial(SimpleHTTPRequestHandler, directory=str(folder))

if __name__ == "__main__":
    print(f"Serving {folder} on port {port}")
    HTTPServer(("0.0.0.0", port), handler).serve_forever()
