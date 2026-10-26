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

A tiny repo that builds and publishes a PHP-FPM image (PHP 7.4 from Ondřej Surý's
[packages.sury.org](https://packages.sury.org/php/) on `debian:trixie-slim`)
with common extensions, sendmail and Xdebug, timezone Asia/Jakarta. There is no application code: the product
is the Docker Hub image and its listing (overview, short description, tags, categories).

```
Dockerfile ──► GitHub Actions (one build, tags latest+7.4, amd64+arm64) ──► Docker Hub yohannaftali/php7-fpm
README.md  ──► peter-evans/dockerhub-description / scripts/dockerhub-update.sh ──► Hub overview
```

## Repository Layout

```
Dockerfile                       # FROM debian:${DEBIAN_RELEASE}-slim + sury php${PHP_VERSION}-* packages, sendmail, TZ
docker-php-entrypoint            # own entrypoint: /etc/hosts entry, sendmail restart, php-fpm default
.gitattributes                   # keeps the entrypoint LF on Windows checkouts
README.md                        # human docs AND the Docker Hub overview (synced as-is)
AGENTS.md / CHANGE_HISTORY.md    # agent guide / dated history
CLAUDE.md                        # points agents at this file
.env.example                     # variable names only; real .env is git-ignored
.github/workflows/docker-publish.yml   # build+push (latest, 7.4), then description sync
scripts/dockerhub_update.py      # Docker Hub API helper (stdlib only, run via uv)
scripts/dockerhub-update.sh|.ps1 # bash / PowerShell wrappers around `uv run`
.claude/skills/                  # planner, coder, tester, reviewer (see below)
```

## Key Facts

- **Tags** are the `tags` list in `docker-publish.yml`: `latest` and `7.4`, both the same image.
  Changing tags means editing that list **and** the Tags table in `README.md`.
- **PHP source**: `packages.sury.org/php` (the Debian counterpart of `ppa:ondrej/php`), keyring from
  `debsuryorg-archive-keyring.deb`. It still ships security backports for 7.4 (e.g. PHP2Shell,
  CVE-2026-109618/109619, in `7.4.33-31`); the weekly rebuild is what delivers them, keep it.
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
- Keep the image **behaviorally compatible with the old `php:7-fpm`-based image** (apps depend on it):
  `php-fpm` in foreground on `:9000`, `clear_env = no`, logs to stderr, `WORKDIR /var/www/html`,
  `STOPSIGNAL SIGQUIT`, user ini in `/usr/local/etc/php/conf.d` (via `PHP_INI_SCAN_DIR=:...`),
  pools in `/usr/local/etc/php-fpm.d` (symlink to `/etc/php/7.4/fpm/pool.d`). `docker-php-ext-*`
  helpers do not exist; extensions come from `php7.4-*` apt packages. Known gap: `pcntl` is CLI-only.
- Xdebug comes from `php7.4-xdebug` (3.1.6, last release supporting 7.4). `xdebug.remote_*` settings
  are Xdebug 2 names and are ignored by 3.x.
- Timezone is **Asia/Jakarta for both the OS (`TZ`) and PHP** (decided 2026-10-26, replacing the
  2026-10-05 "PHP stays UTC" rule): `conf.d/00-timezone.ini` sets `date.timezone=${TZ}`.
  Do not change PHP's timezone without asking.
- Versions go through the `PHP_VERSION` (`7.4`) and `DEBIAN_RELEASE` (`trixie`) build args, not separate Dockerfiles.
- Python scripts are stdlib-only and run through `uv` (`uv run scripts/dockerhub_update.py`);
  bash and PowerShell wrappers must stay thin and behave identically.
- Commit message ends with the attribution trailer configured for the session.
- Pushing to `main` publishes images to Docker Hub. Treat it as a release.

## Validation (before pushing)

```bash
docker build -t php-test .
docker run --rm php-test php -v                       # PHP 7.4.x
docker run --rm php-test date +%Z                     # WIB (OS)
docker run --rm php-test php -r 'echo date_default_timezone_get();'   # Asia/Jakarta
docker run --rm php-test php-fpm -t                    # config valid
docker build --build-arg DEBIAN_RELEASE=bookworm -t php-test:bookworm .   # optional
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
