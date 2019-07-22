FROM php:7.3-fpm-stretch

# Copy composer.lock and composer.json
COPY composer.json /var/www/html

# Set working directory
WORKDIR /var/www/html

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    default-mysql-client \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    libzip-dev \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl
RUN docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/
RUN docker-php-ext-install gd

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add user for laravel application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# Copy existing application directory contents
COPY . /var/www/html
RUN composer install

RUN mkdir storage/logs
RUN touch storage/logs/laravel.log

# Copy existing application directory permissions
COPY --chown=www:www . /var/www/html

# Change current user to www
USER www

RUN echo APP_KEY= > .env && php artisan key:generate --force

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["/bin/sh", "-c", "php artisan migrate --force && php-fpm"]
