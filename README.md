# yohannaftali/php7-fpm

[![Docker Pulls](https://img.shields.io/docker/pulls/yohannaftali/php7-fpm)](https://hub.docker.com/r/yohannaftali/php7-fpm)
[![Docker Image Size](https://img.shields.io/docker/image-size/yohannaftali/php7-fpm/latest)](https://hub.docker.com/r/yohannaftali/php7-fpm)

PHP 7.4-FPM image built from [Ondřej Surý's Debian packages](https://packages.sury.org/php/) (which still receive security backports) with common extensions, sendmail and Xdebug, with both the container clock and PHP set to **Asia/Jakarta (WIB, UTC+7)**.

- Docker Hub: <https://hub.docker.com/r/yohannaftali/php7-fpm>
- Source code (Dockerfile, build workflow, scripts): <https://github.com/yohannaftali/dockerhub-yohannaftali-php7-fpm>
- Issues and feature requests: <https://github.com/yohannaftali/dockerhub-yohannaftali-php7-fpm/issues>

> **Note:** PHP 7.4 is end-of-life upstream. This image is meant for legacy applications that still need PHP 7. It runs on a supported Debian release (13, trixie) and uses PHP packages from [packages.sury.org](https://packages.sury.org/php/), where Ondřej Surý backports security fixes from newer PHP branches (for example PHP2Shell, CVE-2026-109618 and CVE-2026-109619, fixed in `7.4.33-31`). The image is rebuilt weekly to pick these up, so pull regularly. Backports are best-effort; plan a migration to a supported PHP version.

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

Built `FROM debian:trixie-slim` with PHP 7.4.33 from `packages.sury.org` (`php7.4-fpm`, `php7.4-cli` and extension packages) and adds:

- **Timezone**: `TZ=Asia/Jakarta` for the operating system (`date`, logs, cron). PHP's `date.timezone` is also `Asia/Jakarta` (`/usr/local/etc/php/conf.d/00-timezone.ini`). Override it with `date_default_timezone_set()` or your own `date.timezone` ini in that directory (e.g. `zz-timezone.ini`) if you need another zone.
- **Extensions**: `gd`, `mysqli`, `pdo`, `pdo_mysql`, `pgsql`, `pdo_pgsql`, `xmlrpc`, `zip`, `opcache`, `soap`, `bcmath`, `mbstring`, `intl`, `curl`, `xml`, `sqlite3`, `apcu`, `xdebug` (3.1.6, the last release supporting PHP 7.4), plus Debian's defaults (`calendar`, `exif`, `gettext`, `sockets`, `sysv*`, ...). `pcntl` is available on the CLI only (Debian does not build it for FPM).
- **Official-image layout**: `php-fpm` runs in the foreground on port `9000` as `www-data`, logs to stderr, passes the container environment to workers (`clear_env = no`), `WORKDIR /var/www/html`, `STOPSIGNAL SIGQUIT`.
- **Mail**: `sendmail` configured as `sendmail_path`. The entrypoint restarts it on container start.
- **Hosts entry**: the entrypoint appends the container's IP and hostname to `/etc/hosts` (needed by sendmail).
- **Tools**: `nano`, `wget`, `curl`, `zip`, `unzip`, and `jpegoptim`, `optipng`, `pngquant`, `gifsicle`.

### Configuration paths

| What | Path |
| --- | --- |
| Your extra `.ini` files | `/usr/local/etc/php/conf.d/` (scanned after the Debian defaults) |
| Your FPM pool files | `/usr/local/etc/php-fpm.d/` (link to `/etc/php/7.4/fpm/pool.d/`, default pool `www.conf`) |
| Main `php.ini` | `/etc/php/7.4/fpm/php.ini` and `/etc/php/7.4/cli/php.ini` |

The `docker-php-ext-*` and `docker-php-source` helpers of the official image are **not** included. To add an extension in a derived image, install the Debian package, for example `RUN apt-get update && apt-get install -y php7.4-redis`.

Xdebug is installed but not started automatically (`xdebug.remote_autostart=off`). Note that `xdebug.remote_*` are Xdebug 2 setting names and are ignored by Xdebug 3, so configure it with `xdebug.mode` and `xdebug.client_host` through your own ini file.

## Tags

| Tag | Contents |
| --- | --- |
| `latest` | PHP 7.4.33 (sury.org) on Debian 13 trixie |
| `7.4` | same image as `latest` |

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
docker run --rm yohannaftali/php7-fpm php -r 'echo date_default_timezone_get();'   # Asia/Jakarta
docker run --rm yohannaftali/php7-fpm php -m
```

## Build (maintainers)

```bash
docker login

# latest
docker build -t yohannaftali/php7-fpm:latest .

# build args: PHP_VERSION (default 7.4), DEBIAN_RELEASE (default trixie)
docker build --build-arg DEBIAN_RELEASE=bookworm -t php7-fpm:bookworm .

docker push yohannaftali/php7-fpm --all-tags
```

Multi-arch (amd64 + arm64):

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t yohannaftali/php7-fpm:latest -t yohannaftali/php7-fpm:7.4 --push .
```

## Automated publishing

`.github/workflows/docker-publish.yml` builds and pushes the image (tags `latest` and `7.4`) on every push to `main`, weekly (to pick up new sury.org security builds), and on manual dispatch. It also syncs this README to the Docker Hub **overview** and the short **description**.

Required GitHub repository secrets:

| Secret | Value |
| --- | --- |
| `DOCKERHUB_USERNAME` | `yohannaftali` |
| `DOCKERHUB_TOKEN` | Docker Hub access token with *Read, Write, Delete* scope |

To change which tags are published, edit `tags` in the workflow and the Tags table above.

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

The Dockerfile in this repository is provided as-is. PHP is licensed under the PHP License. PHP packages are built and distributed by Ondřej Surý at <https://packages.sury.org/php/>.
