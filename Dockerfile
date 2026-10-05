ARG PHP_VERSION=7-fpm
FROM php:${PHP_VERSION}

LABEL org.opencontainers.image.title="php7-fpm" \
      org.opencontainers.image.description="PHP 7.4-FPM with common extensions, sendmail, Xdebug, OS timezone Asia/Jakarta, PHP stays UTC" \
      org.opencontainers.image.authors="Yohan Naftali" \
      org.opencontainers.image.source="https://github.com/yohannaftali/dockerhub-yohannaftali-php7-fpm"

ENV TZ=Asia/Jakarta
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Debian 11 (bullseye) is EOL; its packages now live on archive.debian.org
RUN sed -i -e 's|deb.debian.org/debian-security|archive.debian.org/debian-security|g' \
           -e 's|deb.debian.org/debian|archive.debian.org/debian|g' \
           -e '/bullseye-updates/d' /etc/apt/sources.list \
    && echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive

RUN apt-get update && apt-get install -y \
    build-essential \
    libcurl4 \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libonig-dev \
    libpng-dev \
    libpq-dev \
    libwebp-dev \
    libxml2-dev \ 
    libzip-dev \    
    jpegoptim optipng pngquant gifsicle \
    zip \
    unzip \
    zlib1g-dev \
    sendmail \
    nano \
    wget \
    curl
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg
RUN docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd
RUN docker-php-ext-configure mysqli --with-mysqli=mysqlnd
RUN docker-php-ext-configure intl
RUN docker-php-ext-configure zip
RUN docker-php-ext-install -j$(nproc) \ 
    gd \
    mysqli \
    pdo \
    pdo_mysql \
    pgsql \
    pdo_pgsql \
    xmlrpc \ 
    zip \
    opcache \
    soap \
    bcmath \
    mbstring \
    pcntl \
    intl
RUN yes | pecl install \
    apcu \
    xdebug-3.1.6
RUN docker-php-ext-enable \
    mysqli \
    pdo \   
    pdo_mysql \
    pgsql \
    pdo_pgsql \
    apcu \
    xdebug    
RUN echo "sendmail_path=/usr/sbin/sendmail -t -i" >> /usr/local/etc/php/conf.d/sendmail.ini  \
    && echo "xdebug.remote_enable=on" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini
RUN sed -i '/#!\/bin\/sh/aservice sendmail restart' /usr/local/bin/docker-php-entrypoint
RUN sed -i '/#!\/bin\/sh/aecho "$(hostname -i)\t$(hostname) $(hostname).localhost" >> /etc/hosts' /usr/local/bin/docker-php-entrypoint
