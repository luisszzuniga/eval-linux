# Solution Reverse Proxy Sécurisé

Cette solution met en place un serveur web avec authentification, protégé par un reverse proxy Caddy et un système de bannissement d'IP via fail2ban.

## Architecture

La solution s'appuie sur trois composants principaux :

1. Application Flask (authentification et contenu)
2. Reverse Proxy Caddy
3. Protection fail2ban

## Prérequis

- Docker
- Docker Compose
- nftables (installé et activé)

## Installation

1. Cloner le dépôt :
   ```bash
   git clone git@github.com:luisszzuniga/eval-linux.git
   cd exercice2
   ```

2. Démarrer les services :
   ```bash
   cd docker && docker compose up -d
   ```

## Test de la Solution

### 1. Accès à l'Application

1. Ouvrir http://localhost/login dans un navigateur
2. Utiliser les identifiants de test :
   - Username: admin
   - Password: password123

### 2. Test de fail2ban

Pour vérifier que fail2ban fonctionne :

1. Tentez de vous connecter avec de mauvais identifiants 3 fois en moins de 10 minutes
2. Vérifiez le bannissement :
   ```bash
   docker compose exec fail2ban fail2ban-client status flask-auth
   ```

## Structure des Fichiers

```
exercice2/
├── app/
│   └── app.py              # Application Flask
├── config/
│   ├── Caddyfile          # Configuration Caddy
│   ├── jail.local         # Configuration fail2ban
│   └── filter.d/
│       └── flask-auth.conf # Filtre fail2ban
└── docker/
    ├── Dockerfile         # Build de l'app Flask
    └── docker-compose.yml # Orchestration des services
```

## Logs

Les logs sont centralisés et accessibles via Docker :

```bash
# Logs d'authentification
docker compose exec app cat /var/log/auth.log

# Logs Caddy
docker compose exec caddy cat /var/log/caddy/access.log

# Statut fail2ban
docker compose exec fail2ban fail2ban-client status
```
