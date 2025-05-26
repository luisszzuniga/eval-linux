#!/bin/bash

# Démarrage du service cron
service cron start

wait_for_mysql() {
    echo "Attente de la disponibilité de MySQL..."
    while ! mysqladmin ping -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; do
        sleep 2
    done

    echo "Attente que MySQL soit complètement initialisé..."
    while ! mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
        sleep 2
    done
}

check_initialization() {
    if mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "USE production_db; SHOW TABLES LIKE 'clients'" 2>/dev/null | grep -q 'clients'; then
        return 0 # Déjà initialisé
    else
        return 1 # Pas encore initialisé
    fi
}

if [ ! -z "$MYSQL_HOST" ]; then
    wait_for_mysql
    
    if ! check_initialization; then
        echo "Première initialisation détectée, configuration de la base de données..."
        
        echo "Attribution des droits avec l'utilisateur root..."
        mysql -h"$MYSQL_HOST" -uroot -p"$MYSQL_ROOT_PASSWORD" < /grant_privileges.sql
        
        echo "Initialisation de la base de données..."
        mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" < /sql/init_database.sql
        
        echo "Initialisation terminée avec succès."
    else
        echo "Base de données déjà initialisée, pas besoin de réinitialiser."
    fi
fi

tail -f /dev/null 