#!/bin/bash

# Config
DEST_FOLDER="/home/syncer"
USER_GROUP="syncer:syncer"

# Create the folders if they don't exist
mkdir -p $DEST_FOLDER/bin/
mkdir -p $DEST_FOLDER/etc/

# Copy the files
cp ../bin/nextcloud_backup.sh $DEST_FOLDER/bin/nextcloud_backup.sh
cp ../etc/nextcloud_backup.conf $DEST_FOLDER/etc/nextcloud_backup.conf

# Change the ownership to the syncer user
chown -R $USER_GROUP $DEST_FOLDER/bin
chown -R $USER_GROUP $DEST_FOLDER/etc

# Set permissions for the script and config file
chmod 700 $DEST_FOLDER/bin/nextcloud_backup.sh
chmod 600 $DEST_FOLDER/etc/nextcloud_backup.conf


echo "Nextcloud backup script and configuration installed in $DEST_FOLDER"