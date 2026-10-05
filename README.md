# yohannaftali/php7-fpm

[![Docker Pulls](https://img.shields.io/docker/pulls/yohannaftali/php7-fpm)](https://hub.docker.com/r/yohannaftali/php7-fpm)
[![Docker Image Size](https://img.shields.io/docker/image-size/yohannaftali/php7-fpm/latest)](https://hub.docker.com/r/yohannaftali/php7-fpm)

[PHP 7.4-FPM](https://hub.docker.com/_/php) image with common extensions, sendmail and Xdebug, preconfigured with the **Asia/Jakarta (WIB, UTC+7)** timezone.

- Docker Hub: <https://hub.docker.com/r/yohannaftali/php7-fpm>
- Source code (Dockerfile, build workflow, scripts): <https://github.com/yohannaftali/dockerhub-yohannaftali-php7-fpm>
- Issues and feature requests: <https://github.com/yohannaftali/dockerhub-yohannaftali-php7-fpm/issues>

> **Note:** PHP 7.4 and Debian 11 (bullseye) are end-of-life. This image is meant for legacy applications that still need PHP 7. Packages come from `archive.debian.org`, and OS and PHP security fixes are no longer published. Do not expose it to untrusted input without other mitigations.

## Use this image

No build needed. Pull the prebuilt image straight from Docker Hub:

```bash
docker pull yohannaftali/php7-fpm
```

Or reference it in your `docker-compose.yml`:

```yaml
services:
  php:
    image: yohannaftali/php7-fpm:latest
```

## Overview

Built `FROM php:7-fpm` (PHP 7.4.33, Debian 11) and adds:

- **Timezone**: `TZ=Asia/Jakarta`.
- **Extensions**: `gd` (freetype, jpeg, webp libs), `mysqli`, `pdo`, `pdo_mysql`, `pgsql`, `pdo_pgsql`, `xmlrpc`, `zip`, `opcache`, `soap`, `bcmath`, `mbstring`, `pcntl`, `intl`, `apcu`, `xdebug` (3.1.6, the last release supporting PHP 7.4).
- **Mail**: `sendmail` configured as `sendmail_path`. The entrypoint restarts it on container start.
- **Hosts entry**: the entrypoint appends the container's IP and hostname to `/etc/hosts` (needed by sendmail).
- **Tools**: `nano`, `wget`, `curl`, `zip`, `unzip`, and `jpegoptim`, `optipng`, `pngquant`, `gifsicle`.

Xdebug is installed but not started automatically (`xdebug.remote_autostart=off`). Note that `xdebug.remote_*` are Xdebug 2 setting names and are ignored by Xdebug 3, so configure it with `xdebug.mode` and `xdebug.client_host` through your own ini file.

## Tags

| Tag | Base image |
| --- | --- |
| `latest` | `php:7-fpm` (PHP 7.4.33) |
| `7.4` | `php:7.4-fpm` |

## Quick start

```yaml
services:
  php:
    image: yohannaftali/php7-fpm:latest
    restart: unless-stopped
    volumes:
      - ./app:/var/www/html
    expose:
      - "9000"

  web:
    image: nginx:stable
    ports:
      - "8080:80"
    volumes:
      - ./app:/var/www/html:ro
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - php
```

Verify the image:

```bash
docker run --rm yohannaftali/php7-fpm php -v
docker run --rm yohannaftali/php7-fpm date +%Z      # WIB
docker run --rm yohannaftali/php7-fpm php -m
```

## Build (maintainers)

```bash
docker login

# latest
docker build -t yohannaftali/php7-fpm:latest .

# specific base tag
docker build --build-arg PHP_VERSION=7.4-fpm -t yohannaftali/php7-fpm:7.4 .

docker push yohannaftali/php7-fpm --all-tags
```

Multi-arch (amd64 + arm64):

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg PHP_VERSION=7.4-fpm \
  -t yohannaftali/php7-fpm:7.4 --push .
```

## Automated publishing

`.github/workflows/docker-publish.yml` builds and pushes the images on every push to `main`, weekly, and on manual dispatch. It also syncs this README to the Docker Hub **overview** and the short **description**.

Required GitHub repository secrets:

| Secret | Value |
| --- | --- |
| `DOCKERHUB_USERNAME` | `yohannaftali` |
| `DOCKERHUB_TOKEN` | Docker Hub access token with *Read, Write, Delete* scope |

To change which tags are published, edit the `include` matrix in the workflow and the Tags table above.

## Maintaining the Docker Hub repository

- **Overview**: synced from this `README.md` by the workflow.
- **Short description**: set in the workflow (`short-description`), max 100 characters.
- **Manual sync / status**: see [Maintenance scripts](#maintenance-scripts).
- **Category**: not exposed through the API; set manually in *Repository → Settings → Categories*.
- **Tags**: remove stale tags in *Repository → Tags*.

## Maintenance scripts

Helper scripts in `scripts/` manage the Docker Hub repository from your machine. They need [uv](https://docs.astral.sh/uv/) and a `.env` file (copy `.env.example`) with `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`. There are no other dependencies.

| Command | Action |
| --- | --- |
| *(none)* / `sync` | Push `README.md` as the overview and set the short description |
| `status` | Show description, categories, pull and star counts |
| `tags` | List tags with last update and size |
| `delete-tag <tag>` | Delete a tag |

Bash:

```bash
./scripts/dockerhub-update.sh            # sync
./scripts/dockerhub-update.sh status
./scripts/dockerhub-update.sh tags
./scripts/dockerhub-update.sh delete-tag 7.4
```

PowerShell:

```powershell
.\scripts\dockerhub-update.ps1            # sync
.\scripts\dockerhub-update.ps1 status
.\scripts\dockerhub-update.ps1 tags
.\scripts\dockerhub-update.ps1 delete-tag 7.4
```

Both wrappers call `scripts/dockerhub_update.py` through `uv run`. Set `DOCKERHUB_REPO` to target a repository other than `php7-fpm`.

## Source and contributing

The Dockerfile, GitHub Actions workflow and maintenance scripts live at <https://github.com/yohannaftali/dockerhub-yohannaftali-php7-fpm>. Open an issue there to report a problem.

## License

The Dockerfile in this repository is provided as-is. PHP is licensed under the PHP License; see the [official image](https://hub.docker.com/_/php) for details.
