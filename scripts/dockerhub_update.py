#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Update the Docker Hub repository metadata from this repo (stdlib only).

Usage:
  uv run scripts/dockerhub_update.py              # sync short + full description from README.md
  uv run scripts/dockerhub_update.py status       # show description, categories, pulls
  uv run scripts/dockerhub_update.py tags         # list tags
  uv run scripts/dockerhub_update.py delete-tag <tag>

Reads DOCKERHUB_USERNAME and DOCKERHUB_TOKEN from the environment or .env.
The token needs "Read, Write, Delete" scope.
Categories cannot be set through the API; use the Docker Hub web UI.
"""
import json
import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
API = "https://hub.docker.com/v2"
REPO = os.environ.get("DOCKERHUB_REPO", "php7-fpm")
SHORT_DESCRIPTION = os.environ.get(
    "SHORT_DESCRIPTION",
    "PHP 7.4-FPM with common extensions, sendmail, Xdebug and Asia/Jakarta timezone.",
)


def load_env():
    env_file = ROOT / ".env"
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            key, sep, value = line.partition("=")
            if sep and not line.lstrip().startswith("#"):
                os.environ.setdefault(key.strip(), value.strip().strip("\"'"))


def request(method, url, body=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req) as res:
        raw = res.read()
        return json.loads(raw) if raw else None


def main():
    load_env()
    user = os.environ.get("DOCKERHUB_USERNAME")
    password = os.environ.get("DOCKERHUB_TOKEN")
    if not user or not password:
        sys.exit("DOCKERHUB_USERNAME and DOCKERHUB_TOKEN must be set (env or .env)")

    jwt = request("POST", f"{API}/users/login", {"username": user, "password": password})["token"]
    url = f"{API}/repositories/{user}/{REPO}"
    args = sys.argv[1:]
    cmd = args[0] if args else "sync"

    def status():
        r = request("GET", url + "/", token=jwt)
        print(json.dumps({
            "name": f"{user}/{REPO}",
            "description": r["description"],
            "categories": [c["name"] for c in r.get("categories") or []],
            "pull_count": r["pull_count"],
            "star_count": r["star_count"],
            "last_updated": r["last_updated"],
        }, indent=2))

    if cmd == "sync":
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        request("PATCH", url + "/", {"description": SHORT_DESCRIPTION, "full_description": readme}, jwt)
        print(f"Updated description and overview for {user}/{REPO}")
        status()
    elif cmd == "status":
        status()
    elif cmd == "tags":
        for t in request("GET", url + "/tags?page_size=100", token=jwt)["results"]:
            print(f"{t['name']}\t{t['last_updated']}\t{t['full_size']} bytes")
    elif cmd == "delete-tag" and len(args) == 2:
        request("DELETE", f"{url}/tags/{args[1]}/", token=jwt)
        print(f"Deleted tag {args[1]}")
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
