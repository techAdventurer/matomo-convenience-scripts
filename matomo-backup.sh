#!/bin/bash

################################
##    Matomo backup script    ##
################################

# Logging should be enabled by adding a redirection to /var/logs/matomo-backup.sh when calling the script.
# This script does not enable maintenance mode for matomo before dumping the database!

MATOMO_APP_NAME="Analytics"
MATOMO_DB_NAME="matomo"
MATOMO_SOURCE_PATH="/var/www/matomo"
MATOMO_CONFIG_PATH="$MATOMO_SOURCE_PATH/config"
MATOMO_BACKUP_PATH="/tmp/matomo_backup"
MATOMO_BACKUP_DROP_OFF="/home/service_backup"

APACHE_CONF_PATH="/etc/apache2/sites-available"
PHP_INI_FILE="/etc/php/7.3/apache2/php.ini"

echo -e "\n$(date --rfc-3339="seconds")\tStarting backup script for \"$MATOMO_APP_NAME\"."


if $(test -d $MATOMO_BACKUP_PATH)
then
	echo -e "$(date --rfc-3339="seconds")\tTemporary backup directory already exists. Deleting its contents to make room for the new files."
	rm -r $MATOMO_BACKUP_PATH/*
else
	echo -e "$(date --rfc-3339="seconds")\tTemporary backup directory NOT found at $MATOMO_BACKUP_PATH - Creating it."
	mkdir $MATOMO_BACKUP_PATH
fi

echo -e "$(date --rfc-3339="seconds")\tCreating manifest file with script settings."
echo -e "Archive creation date: $(date --rfc-3339="seconds")" >> $MATOMO_BACKUP_PATH/README.md
echo -e "\nSettings:" >> $MATOMO_BACKUP_PATH/README.md
echo -e " - MATOMO_APP_NAME: $MATOMO_APP_NAME" >> $MATOMO_BACKUP_PATH/README.md
echo -e " - MATOMO_SOURCE_PATH: $MATOMO_SOURCE_PATH" >> $MATOMO_BACKUP_PATH/README.md
echo -e " - MATOMO_CONFIG_PATH: $MATOMO_CONFIG_PATH" >> $MATOMO_BACKUP_PATH/README.md
echo -e " - APACHE_CONF_PATH: $APACHE_CONF_PATH" >> $MATOMO_BACKUP_PATH/README.md
echo -e " - PHP_INI_FILE: $PHP_INI_FILE" >> $MATOMO_BACKUP_PATH/README.md

echo -e "$(date --rfc-3339="seconds")\tDumping $MATOMO_DB_NAME database."
sudo mysqldump --opt $MATOMO_DB_NAME > $MATOMO_BACKUP_PATH/$MATOMO_DB_NAME-db-dump.sql

echo -e "$(date --rfc-3339="seconds")\tCopying $MATOMO_CONFIG_PATH"
cp -r $MATOMO_CONFIG_PATH $MATOMO_BACKUP_PATH/matomo_config

echo -e "$(date --rfc-3339="seconds")\tCopying $MATOMO_SOURCE_PATH"
cp -r $MATOMO_SOURCE_PATH $MATOMO_BACKUP_PATH/matomo_source

echo -e "$(date --rfc-3339="seconds")\tCopying $APACHE_CONF_PATH"
cp -r $APACHE_CONF_PATH $MATOMO_BACKUP_PATH/apache_conf

echo -e "$(date --rfc-3339="seconds")\tCopying $PHP_INI_FILE"
cp -r $PHP_INI_FILE $MATOMO_BACKUP_PATH/php.ini

echo -e "$(date --rfc-3339="seconds")\tArchiving and compressing files."
cd $MATOMO_BACKUP_PATH
tar -cz -C $MATOMO_BACKUP_PATH -f MATOMO_BCKP-$(date --rfc-3339='date').tar.gz $MATOMO_BACKUP_PATH

echo -e "$(date --rfc-3339="seconds")\tNew archive's hash:"
sha256sum MATOMO_BCKP-$(date --rfc-3339="date").tar.gz

echo -e "$(date --rfc-3339="seconds")\tMoving the backup file to desired folder for pickup."
mv $(echo $MATOMO_BACKUP_PATH)/MATOMO_BCKP-$(date --rfc-3339='date').tar.gz $(echo $MATOMO_BACKUP_DROP_OFF)/

echo -e "$(date --rfc-3339="seconds")\tCleaning up $MATOMO_BACKUP_PATH"
rm -r $MATOMO_BACKUP_PATH/*

echo -e "$(date --rfc-3339="seconds")\tEnd of script."
