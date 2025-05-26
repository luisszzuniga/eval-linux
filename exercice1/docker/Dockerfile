FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    default-mysql-client \
    cron

# Création des répertoires nécessaires
RUN mkdir -p /usr/local/bin /var/reports/ca /var/log
RUN chmod 750 /var/reports/ca

# Copie des scripts
COPY scripts/*.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Copie de la configuration cron
COPY config/rgpd.crontab /etc/cron.d/rgpd
RUN chmod 0644 /etc/cron.d/rgpd

COPY docker/docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Copie du script de droits
COPY sql/grant_privileges.sql /

ENTRYPOINT ["/docker-entrypoint.sh"] 