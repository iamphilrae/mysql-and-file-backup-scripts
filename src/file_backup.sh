#!/bin/sh


###################
#
# File Backup Script
# ------------------
#
# Daily web server file backup to be run manually or
# via a daily cron job
#
#
#
# FILE SAVING LOGIC
#
# Latest backup named after username and overwritten daily
# e.g. hostname__FILES__latest__username__directory.tar.gz
#
# Daily backups named after days of the month and rotated monthly
# e.g. hostname__FILES__daily-DD__username__directory.tar.gz
#
# Monthly backups named after days of the month and rotated yearly
# e.g. hostname__FILES__monthly-MM__username__directory.tar.gz
#
# Yearly backups named after year and never rotated
# note will always equal the latest backup until 31st December
# e.g. hostname__FILES__yearly-YYYY__username__directory.tar.gz
#
#
#
#
# EXECUTION COMMANDS
#
# Execution command: ${HOME}/tasks/file_backup.sh
# (to disable output)  ${HOME}/tasks/file_backup.sh > /dev/null
#
#
#
# Restore procedure example for a single file
# gtar --list --verbose --ungzip --file=hostname-public_html.tar.gz
# gtar --extract --preserve --ungzip --interactive --file=file_name_to_restore.tar.gz index.html
#
#
# Author:
# Phil Rae, https://github.com/iamphilrae
#
##



###################
#
# v2
# -----
# Changed method by which non-latest archives are generated.
#
# v1
# -----
# Initial release.
#
#



###################
#
# VARIABLES
#
#

SCRIPT_VERSION="v2"

SOURCES="${HOME}/public_html"
# backups named after host+directory and overwritten daily


DEST="${HOME}/backups"
# place to store backups, either a separate disk or a network mount

EXCLUDE="*.cache"

EXCLUDE="--exclude=*.cache --exclude=__MACOSX --exclude=.DS_Store"
# files to exclude from backups, include flags

NOW="$(date +"%Y-%m-%d %T")"




#####################
#
# SCRIPT EXECUTION
#
# The main archiving function, result are tarred gzipped
# archives with permissions intact
#
#
echo
echo
echo "=========================================="
echo "------------------------------------------"
echo
echo "Beginning File Backup Script $SCRIPT_VERSION"
echo "$NOW"
echo


MYSCRIPT="$(basename $0)"
TARPATH="/bin/gtar"
EXTRAFLAGS=""


#
# Check for whether script executor is root and warn if not
#
USER=$(id | grep root | wc -l)

if [ $USER -eq 0 ]; then
 	echo "Warning: must backup as root to preserve file permissions"
 	echo
fi


#
# Check that directories are writable
#
if [ ! -w $DEST ]; then
	echo "Error: Unable to write to backup location ($DEST), exiting"
	echo
  exit 1
fi

umask 077


#
# Main archive function
#
tarit()
{
	FILE_PREFIX="${HOSTNAME//./-}__FILES__"
	FILE_POSTFIX="__${LOGNAME}__${SOURCESAFE}"

  FILENAME_LATEST="${FILE_PREFIX}latest${FILE_POSTFIX}.tar.gz"
  FILENAME_DAILY="${FILE_PREFIX}daily-$(date +%d)${FILE_POSTFIX}.tar.gz"
  FILENAME_MONTHLY="${FILE_PREFIX}monthly-$(date +%m)${FILE_POSTFIX}.tar.gz"
  FILENAME_YEARLY="${FILE_PREFIX}yearly-$(date +%Y)${FILE_POSTFIX}.tar.gz"


	$TARPATH --create --one-file-system  --same-permissions \
  	$EXCLUDE $EXTRAFLAGS --totals  --gzip $SOURCE  \
  	--file=$DEST/$FILENAME_LATEST 2>&1 | logger -t "$MYSCRIPT: $SOURCESAFE"


  cp ${DEST}/${FILENAME_LATEST} ${DEST}/${FILENAME_DAILY}
  cp ${DEST}/${FILENAME_LATEST} ${DEST}/${FILENAME_MONTHLY}
  cp ${DEST}/${FILENAME_LATEST} ${DEST}/${FILENAME_YEARLY}


  echo "Saved: $DEST/$FILENAME_LATEST"
}


# Loop through latest archive sources
for SOURCE in $SOURCES
do
	if [ -d $SOURCE ]; then
		PERIOD="latest"
	  SOURCESAFE="$(basename $SOURCE)"
	  tarit

	else
	  echo "$SOURCE not found, skipping"
	fi
done


echo
echo "Backup complete!"
echo "Backup location: $DEST"
echo
echo "__________________________________________"
echo "=========================================="
echo
echo
