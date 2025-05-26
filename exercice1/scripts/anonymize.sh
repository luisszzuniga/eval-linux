#!/bin/bash

# Configuration
DB_USER="rgpd_user"
DB_PASS="password"
PROD_DB="production_db"
ARCHIVE_DB="archive_db"
LOG_FILE="/var/log/rgpd_anonymization.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

check_arguments() {
    if [ $# -ne 1 ]; then
        log_message "Usage: $0 <client_id>"
        exit 1
    fi
}

verify_client_exists() {
    local client_id=$1
    local client_exists
    
    client_exists=$(mysql -u"$DB_USER" -p"$DB_PASS" "$PROD_DB" -N -e "
        SELECT COUNT(*) 
        FROM clients 
        WHERE id=$client_id AND actif = TRUE;")

    if [ "$client_exists" -eq 0 ]; then
        log_message "Client $client_id non trouvé ou déjà anonymisé"
        exit 1
    fi
}

get_client_info() {
    local client_id=$1
    local client_info
    
    client_info=$(mysql -u"$DB_USER" -p"$DB_PASS" "$PROD_DB" -N -e "
        SELECT email, adresse 
        FROM clients 
        WHERE id=$client_id;")
    
    echo "$client_info"
}

generate_client_hash() {
    local client_id=$1
    local email=$2
    
    echo "$client_id-$email" | sha256sum | cut -d' ' -f1
}

extract_region() {
    local adresse=$1
    
    echo "$adresse" | awk -F',' '{print $NF}' | sed 's/^ *//'
}

check_if_archived() {
    local client_hash=$1
    local is_archived
    
    is_archived=$(mysql -u"$DB_USER" -p"$DB_PASS" "$ARCHIVE_DB" -N -e "
        SELECT COUNT(*) 
        FROM clients_archive 
        WHERE client_hash='$client_hash';")
    
    echo "$is_archived"
}

archive_client_data() {
    local client_id=$1
    local client_hash=$2
    local region=$3
    
    # Vérifier si le client est déjà archivé
    if [ "$(check_if_archived "$client_hash")" -gt 0 ]; then
        log_message "Client $client_id déjà archivé (hash: $client_hash)"
        return 0
    fi
    
    mysql -u"$DB_USER" -p"$DB_PASS" "$ARCHIVE_DB" -e "
        INSERT INTO clients_archive (client_hash, region, derniere_activite) 
        SELECT '$client_hash', 
               '$region', 
               derniere_activite 
        FROM $PROD_DB.clients 
        WHERE id=$client_id;"

    if [ $? -ne 0 ]; then
        log_message "Erreur lors de l'archivage des données client"
        exit 1
    fi
}

archive_client_invoices() {
    local client_id=$1
    local client_hash=$2
    
    # Vérifier si les factures sont déjà archivées
    local invoices_archived
    invoices_archived=$(mysql -u"$DB_USER" -p"$DB_PASS" "$ARCHIVE_DB" -N -e "
        SELECT COUNT(*) 
        FROM factures_archive 
        WHERE client_hash='$client_hash';")
    
    if [ "$invoices_archived" -gt 0 ]; then
        log_message "Factures du client $client_id déjà archivées"
        return 0
    fi
    
    mysql -u"$DB_USER" -p"$DB_PASS" "$ARCHIVE_DB" -e "
        INSERT INTO factures_archive (client_hash, montant_ttc, date_facture) 
        SELECT '$client_hash', 
               montant_ttc, 
               date_facture 
        FROM $PROD_DB.factures 
        WHERE client_id=$client_id;"

    if [ $? -ne 0 ]; then
        log_message "Erreur lors de l'archivage des factures"
        exit 1
    fi
}

anonymize_client_data() {
    local client_id=$1
    local client_hash=$2
    
    mysql -u"$DB_USER" -p"$DB_PASS" "$PROD_DB" -e "
        UPDATE clients 
        SET nom = 'ANONYME',
            prenom = 'ANONYME',
            email = CONCAT('anonyme_', '$client_hash', '@deleted.com'),
            adresse = 'ANONYME',
            mot_de_passe = SHA2('DELETED_ACCOUNT', 256),
            actif = FALSE 
        WHERE id=$client_id;"

    if [ $? -ne 0 ]; then
        log_message "Erreur lors de l'anonymisation des données client"
        exit 1
    fi
    
    # Suppression des factures après archivage réussi
    mysql -u"$DB_USER" -p"$DB_PASS" "$PROD_DB" -e "
        DELETE FROM factures 
        WHERE client_id=$client_id;"
}

main() {
    local client_id=$1
    local client_info
    local email
    local adresse
    local client_hash
    local region

    check_arguments "$@"
    verify_client_exists "$client_id"

    client_info=$(get_client_info "$client_id")
    read -r email adresse <<< "$client_info"

    client_hash=$(generate_client_hash "$client_id" "$email")
    region=$(extract_region "$adresse")

    log_message "Début de l'anonymisation du client $client_id"

    archive_client_data "$client_id" "$client_hash" "$region"
    archive_client_invoices "$client_id" "$client_hash"
    anonymize_client_data "$client_id" "$client_hash"

    log_message "Client $client_id anonymisé avec succès (hash: $client_hash)"
}

main "$@" 