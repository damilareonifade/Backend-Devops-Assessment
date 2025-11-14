# Stage 0: base with required system packages and PHP extensions
FROM php:8.3-fpm AS base

ENV COMPOSER_ALLOW_SUPERUSER=1
WORKDIR /var/www/html

# Install system deps and php build deps
RUN apt-get update && apt-get install -y \
    git curl zip unzip gnupg build-essential libzip-dev libpng-dev libonig-dev libxml2-dev \
    libssl-dev protobuf-compiler libprotobuf-dev pkg-config wget ca-certificates \
    && docker-php-ext-install pdo_mysql zip bcmath gd opcache pcntl

# Install pecl extensions grpc and protobuf
RUN pecl channel-update pecl.php.net \
    && pecl install grpc protobuf \
    && docker-php-ext-enable grpc protobuf

# Install composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Stage 1: build app (install composer deps + node)
FROM base AS build
WORKDIR /var/www/html
COPY composer.json composer.lock ./
# if you use node assets, copy lockfiles and package.json
COPY package.json package-lock.json ./
# install PHP deps
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader
# install npm deps and build assets (optional)
RUN apt-get update && apt-get install -y nodejs npm && npm ci && npm run build || true

# Copy full app
COPY . .

# Stage 2: web image (Octane + RoadRunner runtime for web)
FROM base AS web
WORKDIR /var/www/html
# Copy app
COPY --from=build /var/www/html /var/www/html

# Install laravel octane & roadrunner adapter (if not already in composer.json)
RUN composer require laravel/octane spiral/roadrunner --no-interaction || true

# Install RoadRunner binary
RUN curl -L "https://github.com/roadrunner-server/roadrunner/releases/latest/download/roadrunner-linux-amd64" -o /usr/local/bin/rr \
    && chmod +x /usr/local/bin/rr

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true

EXPOSE 80

# Default to serving Octane with RoadRunner - the container entrypoint can be overridden in k8s
CMD ["rr", "serve", "-c", "/etc/roadrunner/.rr-web.yaml"]

# Stage 3: worker image (same app but default entry is worker rr config)
FROM base AS worker
WORKDIR /var/www/html
COPY --from=build /var/www/html /var/www/html

# install octane & roadrunner if needed (should be present)
RUN composer require laravel/octane spiral/roadrunner --no-interaction || true

# Install RoadRunner binary
RUN curl -L "https://github.com/roadrunner-server/roadrunner/releases/latest/download/roadrunner-linux-amd64" -o /usr/local/bin/rr \
    && chmod +x /usr/local/bin/rr

# The default command will run RoadRunner with the worker config (overridable in k8s)
CMD ["rr", "serve", "-c", "/etc/roadrunner/.rr-worker.yaml"]
