# ---------- Base PHP ----------
FROM php:8.2-cli

# Installer dépendances système
RUN apt-get update && apt-get install -y \
    unzip git curl libsqlite3-dev nodejs npm \
    && docker-php-ext-install pdo pdo_sqlite \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Installer Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Définir le dossier de travail
WORKDIR /app

# Copier tous les fichiers du projet
COPY . .

# Créer un .env temporaire si absent
RUN if [ ! -f .env ]; then cp .env.example .env; fi

# Installer dépendances PHP et JS et build assets
RUN composer install --no-dev --optimize-autoloader \
    && npm install \
    && npm run build

# Générer la clé Laravel
RUN php artisan key:generate --force

# Créer SQLite et s'assurer que storage / bootstrap/cache sont présents et writable
RUN mkdir -p database \
    && touch database/database.sqlite \
    && mkdir -p storage/framework/cache/data \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Mettre en cache config/route/view pour optimiser Laravel
RUN php artisan co
