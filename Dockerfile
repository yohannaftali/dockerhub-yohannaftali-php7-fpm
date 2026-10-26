ARG DEBIAN_RELEASE=trixie
FROM debian:${DEBIAN_RELEASE}-slim

ARG DEBIAN_RELEASE
ARG PHP_VERSION=7.4

LABEL org.opencontainers.image.title="php7-fpm" \
      org.opencontainers.image.description="PHP 7.4-FPM (packages.sury.org) on Debian with common extensions, sendmail, Xdebug, timezone Asia/Jakarta (OS and PHP)" \
      org.opencontainers.image.authors="Yohan Naftali" \
      org.opencontainers.image.source="https://github.com/yohannaftali/dockerhub-yohannaftali-php7-fpm"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta \
    PHP_VERSION=${PHP_VERSION} \
    PHP_INI_DIR=/etc/php/${PHP_VERSION} \
    PHP_INI_SCAN_DIR=:/usr/local/etc/php/conf.d
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Ondřej Surý's Debian repository (the Debian counterpart of ppa:ondrej/php) still ships
# patched PHP 7.4 builds; https://packages.sury.org/php/README.txt
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb \
    && dpkg -i /tmp/debsuryorg-archive-keyring.deb \
    && rm /tmp/debsuryorg-archive-keyring.deb \
    && echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ ${DEBIAN_RELEASE} main" \
        > /etc/apt/sources.list.d/php.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-apcu \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-json \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-xdebug \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-xmlrpc \
        php${PHP_VERSION}-zip \
        jpegoptim optipng pngquant gifsicle \
        zip \
        unzip \
        sendmail \
        nano \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Behave like the official php:*-fpm image: `php-fpm` in the foreground on port 9000,
# logs to stderr, env passed to workers, user config in /usr/local/etc/php{,-fpm.d}
RUN ln -s /usr/sbin/php-fpm${PHP_VERSION} /usr/local/sbin/php-fpm \
    && mkdir -p /usr/local/etc/php/conf.d /run/php /var/www/html \
    && ln -s ${PHP_INI_DIR}/fpm/pool.d /usr/local/etc/php-fpm.d \
    && sed -i -e 's|^;\?daemonize = .*|daemonize = no|' \
              -e 's|^error_log = .*|error_log = /proc/self/fd/2|' \
              ${PHP_INI_DIR}/fpm/php-fpm.conf \
    && sed -i -e 's|^listen = .*|listen = 9000|' \
              -e 's|^;clear_env = .*|clear_env = no|' \
              -e 's|^;catch_workers_output = .*|catch_workers_output = yes|' \
              -e 's|^;decorate_workers_output = .*|decorate_workers_output = no|' \
              -e 's|^;access.log = .*|access.log = /proc/self/fd/2|' \
              ${PHP_INI_DIR}/fpm/pool.d/www.conf \
    && chown www-data:www-data /var/www/html

# PHP runs on Jakarta time too (set explicitly instead of relying on Debian's OS-timezone guess)
RUN echo "date.timezone=${TZ}" > /usr/local/etc/php/conf.d/00-timezone.ini \
    && echo "sendmail_path=/usr/sbin/sendmail -t -i" > /usr/local/etc/php/conf.d/sendmail.ini \
    && echo "xdebug.remote_enable=on" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini

COPY docker-php-entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-entrypoint

WORKDIR /var/www/html
ENTRYPOINT ["docker-php-entrypoint"]
STOPSIGNAL SIGQUIT
EXPOSE 9000
CMD ["php-fpm"]
