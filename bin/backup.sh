#!/bin/bash

# Define an array with the list of paths to backup
declare -a FOLDERS_TO_BACKUP=(
    "/etc/caca"
    # Add other folders here
)
	
# Define the base destination folder
BASE_DESTINATION="/root/backup"
	
# Get the current date in yyyy-mm-dd format
CURRENT_DATE=$(date +"%Y-%m-%d")
	
# Create the destination directory with the current date
DESTINATION="$BASE_DESTINATION/$CURRENT_DATE"
mkdir -p "$DESTINATION"
	
# Loop through the array and copy each folder to the destination
for FOLDER in "${FOLDERS_TO_BACKUP[@]}"; do
    # Create the necessary directory structure in the destination
    DEST_FOLDER="$DESTINATION/$FOLDER"
    mkdir -p "$(dirname "$DEST_FOLDER")"
		        
    # Copy the folder to the destination
    cp -r "$FOLDER" "$DEST_FOLDER"
done
				
# Change to the base destination directory
cd "$BASE_DESTINATION"
				
# Create a tar.gz archive of the backup directory
tar -czf "backup-$CURRENT_DATE.tgz" "$CURRENT_DATE"
				
# Optionally, remove the original uncompressed backup folder
# rm -rf "$CURRENT_DATE"
				
echo "Backup completed successfully. Archive created: $BASE_DESTINATION/backup-$CURRENT_DATE.tgz"
