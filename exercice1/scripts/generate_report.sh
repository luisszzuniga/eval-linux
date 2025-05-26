#!/bin/bash

# Configuration
DB_USER="rgpd_user"
DB_PASS="password"
PROD_DB="production_db"
ARCHIVE_DB="archive_db"
REPORT_DIR="/var/reports/ca"
LOG_FILE="/var/log/rgpd_reports.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

check_prerequisites() {
    if [ "$EUID" -ne 0 ]; then
        log_message "Ce script doit être exécuté avec les droits sudo"
        exit 1
    fi
}

setup_environment() {
    mkdir -p "$REPORT_DIR"
    touch "$LOG_FILE"
    chmod 640 "$LOG_FILE"
    chmod 750 "$REPORT_DIR"
}

prepare_report_file() {
    local report_date=$(date +%Y%m%d)
    local report_file="$REPORT_DIR/rapport_ca_$report_date.csv"
    
    # En-tête du fichier CSV
    echo "Année,Mois,CA_Production_TTC,CA_Archive_TTC,CA_Total_TTC" > "$report_file"
    
    echo "$report_file"
}

generate_consolidated_report() {
    local report_file=$1
    
    mysql -u"$DB_USER" -p"$DB_PASS" -e "
        SELECT 
            YEAR(date_facture) as annee,
            MONTH(date_facture) as mois,
            SUM(CASE 
                WHEN db = 'production' THEN montant_ttc 
                ELSE 0 
            END) as ca_production,
            SUM(CASE 
                WHEN db = 'archive' THEN montant_ttc 
                ELSE 0 
            END) as ca_archive,
            SUM(montant_ttc) as ca_total
        FROM (
            SELECT 
                date_facture,
                montant_ttc,
                'production' as db
            FROM $PROD_DB.factures
            UNION ALL
            SELECT 
                date_facture,
                montant_ttc,
                'archive' as db
            FROM $ARCHIVE_DB.factures_archive
        ) as combined_data
        GROUP BY YEAR(date_facture), MONTH(date_facture)
        ORDER BY YEAR(date_facture) DESC, MONTH(date_facture) DESC;" | \
    while read -r annee mois ca_prod ca_archive ca_total; do
        if [ "$annee" != "annee" ]; then
            echo "$annee,$mois,$ca_prod,$ca_archive,$ca_total" >> "$report_file"
        fi
    done
    
    if [ $? -ne 0 ]; then
        log_message "Erreur lors de la génération du rapport"
        return 1
    fi
    
    return 0
}

cleanup_old_reports() {
    find "$REPORT_DIR" -name "rapport_ca_*.csv" -mtime +365 -delete
    if [ $? -ne 0 ]; then
        log_message "Erreur lors du nettoyage des anciens rapports"
        return 1
    fi
    
    return 0
}

main() {
    local report_file
    local errors=0
    
    check_prerequisites
    setup_environment
    
    log_message "Début de la génération du rapport de CA"
    
    report_file=$(prepare_report_file)
    
    if ! generate_consolidated_report "$report_file"; then
        ((errors++))
    fi
    
    if ! cleanup_old_reports; then
        ((errors++))
    fi
    
    log_message "Rapport généré avec succès : $report_file"
    log_message "Fin de la génération du rapport de CA"
    
    return $errors
}

main 