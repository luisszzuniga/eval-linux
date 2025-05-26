# Solution RGPD - Anonymisation et Archivage des Données

Solution automatisée pour gérer l'anonymisation et l'archivage des données clients conformément au RGPD.

> Cette solution a été conçue pour répondre aux exigences du RGPD tout en maintenant une traçabilité des données financières nécessaire pour les obligations légales. L'approche choisie sépare clairement les données actives des données archivées, permettant une gestion granulaire des durées de conservation.

## Architecture de la Solution

La solution repose sur une architecture à deux bases de données :

- `production_db` : Données clients actifs
- `archive_db` : Données anonymisées et archivées

> Le choix d'utiliser deux bases de données distinctes plutôt qu'un simple flag d'archivage permet :
> - Une séparation physique des données conforme aux bonnes pratiques RGPD
> - Une gestion des droits d'accès différenciée
> - Une meilleure performance des requêtes sur les données actives
> - Une facilité de purge des données archivées

## Fonctionnalités

- Anonymisation automatique des données clients inactifs (> 3 ans)
- Archivage des données de facturation (conservation 10 ans)
- Génération de rapports de CA
- Interface d'administration via phpMyAdmin

## Prérequis :
   - Docker
   - Docker Compose

## Installation

1. Cloner le dépôt :
   ```bash
   git clone git@github.com:luisszzuniga/eval-linux.git
   cd exercice1
   ```

2. Démarrage :
   ```bash
   cd docker && docker compose up -d
   ```

## Test des fonctionnalités

La base de données est pré-remplie avec des données de test variées pour démontrer les différentes fonctionnalités.

### 1. Vérification des données initiales

Connectez-vous à phpMyAdmin (http://localhost:8080) et explorez les données :
- 5 clients avec différentes périodes d'inactivité
- 12 factures réparties sur différentes périodes
- 2 clients dépassent le seuil d'inactivité (3 ans)

### 2. Test de l'anonymisation

Les clients "Pierre Bernard" et "Marie Dubois" sont inactifs depuis plus de 3 ans.

1. Lancer la détection des comptes inactifs :
   ```bash
   docker compose exec rgpd check_inactive.sh
   ```
   Résultat attendu : Identification de 2 comptes à anonymiser

2. Vérifier l'anonymisation :
   - Dans `production_db.clients` : les clients ont été supprimés
   - Dans `archive_db.clients_archive` : 2 nouveaux enregistrements anonymisés
   - Dans `archive_db.factures_archive` : les factures associées

### 3. Test des rapports de CA

1. Générer un rapport annuel :
   ```bash
   docker compose exec rgpd generate_report.sh
   ```

2. Vérifier le rapport :
   ```bash
   docker compose exec rgpd ls -l /var/reports/ca
   docker compose exec rgpd cat /var/reports/ca/rapport_ca_YYYY.csv
   ```
   Le rapport inclut :
   - CA des clients actifs (production_db)
   - CA des clients archivés (archive_db)
   - Total consolidé par mois

### 4. Vérification des logs

1. Consulter les logs d'anonymisation :
   ```bash
   docker compose exec rgpd cat /var/log/rgpd_anonymization.log
   ```

2. Consulter les logs de génération des rapports :
   ```bash
   docker compose exec rgpd cat /var/log/rgpd_reports.log
   ```

## Structure du projet

```
exercice1/
├── config/
│   └── rgpd.crontab         # Configuration des tâches planifiées
├── docker/
│   ├── Dockerfile           # Configuration du conteneur RGPD
│   ├── docker-compose.yml   # Configuration des services (MySQL, phpMyAdmin, RGPD)
│   └── docker-entrypoint.sh # Script d'initialisation avec vérification d'état
├── scripts/
│   ├── anonymize.sh         # Script d'anonymisation
│   ├── check_inactive.sh    # Vérification des comptes inactifs
│   └── generate_report.sh   # Génération des rapports
├── sql/
│   └── init_database.sql    # Création et initialisation des bases production_db et archive_db
└── README.md               # Documentation
```
