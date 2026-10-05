# CHANGE_HISTORY.md

Newest first. One dated entry per notable change.

## [2026-10-05] — docs: PHP timezone stays UTC
- Verified that PHP's `date()` reports UTC even though the OS clock is WIB (PHP ignores `TZ` and uses `date.timezone`). Decision: keep PHP on UTC so applications stay datetime-agnostic. README, labels, short description and `AGENTS.md` now say "OS timezone Asia/Jakarta, PHP stays UTC" instead of implying PHP runs on Jakarta time. No Dockerfile behavior change.

## [2026-10-05] — fix + chore: make the image buildable again, apply the shared repo setup
- **Build fix**: the Dockerfile no longer built. Debian 11 (bullseye) is EOL and `bullseye-security` returned 404, so apt now points at `archive.debian.org` (Check-Valid-Until off, `bullseye-updates` dropped). `pecl install xdebug` fetched a release that does not support PHP 7.4, so xdebug is pinned to `3.1.6`.
- **Warning fix**: removed a duplicate `zend_extension` line in the generated `xdebug.ini` (`docker-php-ext-enable` already loads it), which printed "Cannot load Xdebug - it was already loaded" on every `php` start. The `xdebug.remote_*` lines are kept but are Xdebug 2 names and do nothing under 3.x (noted in README).
- `Dockerfile`: `PHP_VERSION` build arg, OCI labels, `ENV TZ=Asia/Jakarta` syntax, trailing newline.
- `.github/workflows/docker-publish.yml`: `include` matrix `latest` (`php:7-fpm`) and `7.4` (`php:7.4-fpm`), amd64+arm64, weekly + on push + manual, then syncs README to the Hub overview. Rebuilds `latest`, last pushed 2022-10-18.
- `README.md`: full rewrite (EOL warning, what the image adds, tags, usage, GitHub links, maintenance scripts). Replaces the old notes that used the wrong Hub URL and `php7-fpm-with-sendmail` names.
- Added `scripts/`, `.env.example`, `.gitignore`, `CLAUDE.md`, `AGENTS.md` and `.claude/skills/` adapted from the sibling Docker Hub repos.
- Docker Hub category still to be set manually in the web UI.

## Earlier
- 2022-10-18: added sendmail and the PostgreSQL extensions; published once as `yohannaftali/php7-fpm:latest`.
- Initial Dockerfile: `FROM php:7-fpm` with the PHP extensions and `TZ=Asia/Jakarta`.
