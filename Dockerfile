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

# S'assurer que le fichier SQLite existe
RUN mkdir -p database && touch database/database.sqlite

# Mettre en cache config/route/view pour optimiser
RUN php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

# Exposer le port utilisé par Laravel
EXPOSE 10000

# Commande de démarrage
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=10000"]
