# Utilise une image PHP officielle avec les extensions nécessaires
FROM php:8.2-cli

# Installe dépendances système + Composer + Node.js
RUN apt-get update && apt-get install -y \
    unzip \
    git \
    curl \
    libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql

# Installer Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Installer Node.js (pour Vite)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Définir le dossier de travail
WORKDIR /app

# Copier tous les fichiers du projet
COPY . .

# Installer dépendances PHP et JS
RUN composer install --no-dev --optimize-autoloader \
    && npm install \
    && npm run build

# Générer la clé Laravel
RUN php artisan key:generate

# Mettre en cache la config/route/vue
RUN php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

# Exposer le port pour Render
EXPOSE 10000

# Lancer Laravel