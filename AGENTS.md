# AGENTS.md

> **READ THIS FIRST.** Every AI agent working in this repository (Claude, Gemini, Copilot,
> Cursor, ...) must read this file before doing anything else. It is the single source of
> truth for what this project is and how to work on it. After any structural change
> (new file, new workflow, new tag, changed secret), update this file in the same change.
>
> **Compaction rule:** keep this file describing the *current* state. Put dated history in
> [`CHANGE_HISTORY.md`](CHANGE_HISTORY.md).

## Repository

- remote: https://github.com/yohannaftali/dockerhub-yohannaftali-php7-fpm
- platform: GitHub (use the `gh` CLI; it is already authenticated on the maintainer's machine)
- default branch: `main`
- Docker Hub image: `yohannaftali/php7-fpm` (https://hub.docker.com/r/yohannaftali/php7-fpm)

## Big Picture

A tiny repo that builds and publishes a [PHP-FPM](https://hub.docker.com/_/php) image (PHP 7.4)
with common extensions, sendmail and Xdebug, timezone Asia/Jakarta. There is no application code: the product
is the Docker Hub image and its listing (overview, short description, tags, categories).

```
Dockerfile ──► GitHub Actions (build matrix, amd64+arm64) ──► Docker Hub yohannaftali/php7-fpm
README.md  ──► peter-evans/dockerhub-description / scripts/dockerhub-update.sh ──► Hub overview
```

## Repository Layout

```
Dockerfile                       # FROM php:${PHP_VERSION}; extensions, sendmail, xdebug, TZ=Asia/Jakarta
README.md                        # human docs AND the Docker Hub overview (synced as-is)
AGENTS.md / CHANGE_HISTORY.md    # agent guide / dated history
CLAUDE.md                        # points agents at this file
.env.example                     # variable names only; real .env is git-ignored
.github/workflows/docker-publish.yml   # build+push matrix, then description sync
scripts/dockerhub_update.py      # Docker Hub API helper (stdlib only, run via uv)
scripts/dockerhub-update.sh|.ps1 # bash / PowerShell wrappers around `uv run`
.claude/skills/                  # planner, coder, tester, reviewer (see below)
```

## Key Facts

- **Tags** are the `include` matrix in `docker-publish.yml`: `latest` (`php:7-fpm`) and `7.4` (`php:7.4-fpm`).
  Adding or dropping a version means editing that matrix **and** the Tags table in `README.md`.
- The workflow runs on push to `main`, weekly (Mon 03:00 UTC, to pick up upstream fixes) and
  manually. The `description` job syncs `README.md` to Docker Hub after all builds pass.
- **Secrets** (GitHub repo secrets): `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` (Docker Hub PAT,
  scope *Read, Write, Delete*; description updates need Delete scope).
- **Categories cannot be set via the Docker Hub API** (it silently ignores them). They are set
  by hand in the web UI. Not set yet.
- **Legacy duplicate Docker Hub repos** (`yohannaftali/yohannaftali-php7-fpm`, `yohannaftali/php7-fpm-with-sendmail`, `yohannaftali/php7-fpm-without-opcache`) are older names for `yohannaftali/php7-fpm`. Other apps still pull them, so they cannot be deleted. They are **frozen**: their overview carries a DEPRECATED notice pointing here (set 2026-10-05) and nothing may be pushed to them (apps may depend on their exact contents). Maintain only `yohannaftali/php7-fpm`.
- `README.md` is published verbatim as the Hub overview: keep it self-contained, no
  repo-relative links that only work on GitHub.

## Conventions & Guardrails

- Never commit `.env` or any token. `.env.example` holds names and placeholders only.
- Never print tokens in output, logs or commit messages. Refer to them as `$TOKEN`.
- Keep the Dockerfile close to the official image. Known constraints: PHP 7.4 and Debian 11 are EOL, so apt is
  pointed at `archive.debian.org`, and xdebug is pinned to `3.1.6` (last release supporting 7.4); do
  not unpin either. `xdebug.remote_*` settings are Xdebug 2 names and are ignored by 3.x. Other behavior belongs to the
  upstream image; do not fork its entrypoint.
- PHP `date.timezone` is deliberately **not** set (stays UTC, decided 2026-10-05: keep PHP datetime-agnostic).
  `TZ=Asia/Jakarta` only affects the OS clock. Do not add `date.timezone` without asking.
- Pinned versions go through the `PHP_VERSION` build arg, not separate Dockerfiles.
- Python scripts are stdlib-only and run through `uv` (`uv run scripts/dockerhub_update.py`);
  bash and PowerShell wrappers must stay thin and behave identically.
- Commit message ends with the attribution trailer configured for the session.
- Pushing to `main` publishes images to Docker Hub. Treat it as a release.

## Validation (before pushing)

```bash
docker build -t php-test .
docker run --rm php-test php -v                       # PHP 7.4.x
docker run --rm php-test date +%Z                     # WIB (OS)
docker run --rm php-test php -r 'echo date_default_timezone_get();'   # UTC (by design)
docker run --rm php-test php-fpm -t                    # config valid
docker build --build-arg PHP_VERSION=7.4-fpm -t php-test:7.4 .
uv run scripts/dockerhub_update.py status             # needs .env; read-only
```

See the `tester` skill for the full smoke test (extensions load, no startup warnings, php-fpm config valid).

## Agent Skills (`.claude/skills/`)

Adapted from the Senar project for a single-image repo (no issue-tracker UI, no browser).

- **`planner`**: create/track GitHub issues with `gh`; checks `CHANGE_HISTORY.md` for
  duplicates and keeps the Tracked Issues table below current.
- **`coder`**: implements an issue (Dockerfile, workflow, scripts, README) per these rules.
- **`tester`**: builds the image locally, smoke-tests it, and only then opens/merges a PR.
- **`reviewer`**: post-merge audit of what landed on `main` and on Docker Hub.

Flow: `planner` -> `coder` -> `tester` -> `reviewer`.

## Tracked Issues

| ID | Title | Status | Last Checked |
|----|-------|--------|--------------|

## Change Log Policy

- `AGENTS.md`: current architecture and rules only.
- `CHANGE_HISTORY.md`: one dated entry per notable change, newest first.
- Any agent making a structural change updates both files in the same change.
