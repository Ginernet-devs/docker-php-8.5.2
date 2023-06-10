FROM php:8.2-fpm as ginernet-php-fpm85
ARG TIMEZONE

LABEL Maintainer="email@javier-rodriguez.com"

#Configuration
ENV ACCEPT_EULA=Y
ARG DEBIAN_FRONTEND=noninteractive

#Utilities
RUN apt-get update && apt-get install -y \
    git \
    openssl \
    unzip \
    wget \
    supervisor \
    cron \
    htop \
    zip \
    vim \
    lsof \
    apt-utils

RUN apt-get install -y \
    zlib1g-dev libpq-dev libc-client-dev libkrb5-dev gnutls-bin

RUN apt-get install -y \
    nginx

#Php 8.0
RUN wget -O phpunit.phar https://phar.phpunit.de/phpunit-8.0.6.phar && \
    chmod +x phpunit.phar &&  cp phpunit.phar /usr/local/lib/php

#Install Composer.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer --version

#TimeZone
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN echo '[PHP]\ndate.timezone ="Europe/Madrid"' > /usr/local/etc/php/php.ini

#PHP Extensions
RUN apt-get install -y libxml2-dev libmcrypt-dev libcurl4-openssl-dev
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install pcntl
RUN docker-php-ext-install sockets
RUN docker-php-ext-install dom
RUN docker-php-ext-install session
RUN docker-php-ext-install pdo
RUN docker-php-ext-install pgsql
RUN docker-php-ext-install pdo_pgsql
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install mysqli
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl
RUN docker-php-ext-install imap
RUN docker-php-ext-install curl
RUN pecl install xmlrpc-1.0.0RC3
RUN docker-php-ext-install xmlwriter
RUN docker-php-ext-install xml
RUN docker-php-ext-install opcache
RUN docker-php-ext-install curl
RUN docker-php-ext-install intl
RUN docker-php-ext-install soap
RUN apt-get install -y libonig-dev
RUN docker-php-ext-install mbstring

RUN apt-get update -y && apt-get install -y libwebp-dev libjpeg62-turbo-dev libpng-dev libxpm-dev \
    libfreetype6-dev zlib1g-dev libzip-dev

RUN docker-php-ext-install zip
RUN docker-php-ext-install gd

##Install Imagemagick & PHP Imagick ext
RUN apt-get update && apt-get install -y \
    libmagickwand-dev --no-install-recommends

##RUN pecl install imagick && docker-php-ext-enable imagick
RUN mkdir -p /usr/src/php/ext/imagick; \
    curl -fsSL https://github.com/Imagick/imagick/archive/06116aa24b76edaf6b1693198f79e6c295eda8a9.tar.gz | tar xvz -C "/usr/src/php/ext/imagick" --strip 1; \ 
    docker-php-ext-install imagick;

##MSQL
# RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
#     && curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list \
#     && apt-get update \
#     && apt-get -y --no-install-recommends install msodbcsql17 unixodbc-dev \
#     && pecl install sqlsrv \
#     && pecl install pdo_sqlsrv \
#     && echo "extension=pdo_sqlsrv.so" >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/30-pdo_sqlsrv.ini \
#     && echo "extension=sqlsrv.so" >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/30-sqlsrv.ini \
#     && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

##Configuración XDEBug
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug
RUN echo 'xdebug.remote_port=9000' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo 'xdebug.remote_enable=1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo 'xdebug.remote_connect_back=1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo 'xdebug.idekey = PHPSTORM' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo 'xdebug.remote_autostart=1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo 'xdebug.max_nesting_level=4096' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

##MAX FILE SIZE
RUN echo 'upload_max_filesize = 20M' >> /usr/local/etc/php/php.ini
RUN echo 'post_max_size = 40M' >> /usr/local/etc/php/php.ini
RUN echo 'display_errors = Off' >> /usr/local/etc/php/php.ini
RUN echo 'error_reporting = E_ERROR' >> /usr/local/etc/php/php.ini
RUN echo 'memory_limit = 512M' >> /usr/local/etc/php/php.ini

##JIT en PHP8
# RUN echo 'opcache.enable=1' >> /usr/local/etc/php/php.ini
# RUN echo 'opcache.enable_cli=1' >> /usr/local/etc/php/php.ini
# RUN echo 'opcache.jit_buffer_size=100M' >> /usr/local/etc/php/php.ini
# RUN echo 'opcache.jit=1255' >> /usr/local/etc/php/php.ini

##Install Symfony Cli
RUN wget https://get.symfony.com/cli/installer -O - | bash
RUN mv /root/.symfony5/bin/symfony /usr/local/bin/symfony

#Clean
RUN rm -rf /var/lib/apt/lists/*

COPY nginx-site.conf /etc/nginx/sites-enabled/default
COPY entrypoint.sh /etc/entrypoint.sh
RUN chmod +x /etc/entrypoint.sh


WORKDIR /var/www

EXPOSE 80 443

ENTRYPOINT [ "/etc/entrypoint.sh" ]