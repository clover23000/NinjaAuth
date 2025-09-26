# ---------- Base PHP ----------
FROM php:8.2-cli

# Installer dépendances système + SQLite + Node.js + npm + git
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

# S'assurer que le fichier SQLite existe
RUN mkdir -p database && touch database/database.sqlite

# Installer dépendances PHP et JS + build assets
RUN composer install --no-dev --optimize-autoloader \
    && npm install \
    && npm run build

# Générer la clé Laravel
RUN php artisan key:generate --force

# Créer les dossiers storage et bootstrap/cache avec permissions
RUN mkdir -p storage/framework/cache/data \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# NOTE: On ne met pas en cache config/route/view ici pour éviter les erreurs de build
# Ces commandes seront exécutées au démarrage

# Exposer le port utilisé par Laravel
EXPOSE 10000

# Commande de démarrage
CMD php artisan config:clear \
    && php artisan route:clear \
    && php artisan view:clear \
    && php artisan serve --host=0.0.0.0 --port=10000
