# dockerhub-php7-fpm
Configured PHP 7-fpm

Docker hub url: https://hub.docker.com/repository/docker/yohannaftali/yohannaftali-php7-fpm

yohannaftali/yohannaftali-php7-fpm

2022-10-18: add sendmail

To compile:

> docker login
> docker build -t php7-fpm-with-sendmail .
> docker tag php7-fpm-with-sendmail:latest yohannaftali/php7-fpm-with-sendmail
> docker push yohannaftali/php7-fpm-with-sendmail:latest
