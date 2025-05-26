#!/bin/bash

# Configuration
DB_USER="rgpd_user"
DB_PASS="password"
PROD_DB="production_db"
LOG_FILE="/var/log/rgpd_anonymization.log"
ANONYMIZE_SCRIPT="/usr/local/bin/anonymize.sh"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

setup_logging() {
    touch "$LOG_FILE"
    chmod 640 "$LOG_FILE"
}

get_inactive_clients() {
    mysql -u"$DB_USER" -p"$DB_PASS" "$PROD_DB" -N -e "
        SELECT id 
        FROM clients 
        WHERE derniere_activite < DATE_SUB(CURRENT_DATE, INTERVAL 3 YEAR)
        AND actif = TRUE;"
}

process_inactive_client() {
    local client_id=$1
    
    "$ANONYMIZE_SCRIPT" "$client_id"
    
    if [ $? -eq 0 ]; then
        log_message "Traitement du client $client_id terminé avec succès"
        return 0
    else
        log_message "Erreur lors du traitement du client $client_id"
        return 1
    fi
}

main() {
    local errors=0

    setup_logging

    log_message "Début de la vérification des comptes inactifs"

    while read -r client_id; do
        if ! process_inactive_client "$client_id"; then
            ((errors++))
        fi
    done < <(get_inactive_clients)

    log_message "Fin de la vérification des comptes inactifs"

    return $errors
}

main
