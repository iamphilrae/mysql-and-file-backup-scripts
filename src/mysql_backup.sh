#!/bin/sh

###################
#
# CONFIGURATION
#

# Database
DB_HOST="localhost"
DB_USER="DATBASE_USERNAME_HERE"
DB_PASS="DATABASE_PASSWORD_HERE"



 
###################
#
# Database Backup Script
# ----------------------
#
# Daily web server mysql database backup to be run
# manually or via a daily cron job.
#
# All databases for a particular account will
# be backed up in this process.
#
#
#
# FILE SAVING LOGIC
#
# Latest backup named after username and overwritten daily
# e.g. hostname__MYSQL__latest__username__database.tar.gz
#
# Daily backups named after days of the month and rotated monthly
# e.g. hostname__MYSQL__daily-DD__username__database.tar.gz
#
# Monthly backups named after days of the month and rotated yearly
# e.g. hostname__MYSQL__monthly-MM__username__database.tar.gz
#
# Yearly backups named after year and never rotated
# note will always equal the latest backup until 31st December
# e.g. hostname__MYSQL__yearly-YYYY__username__database.tar.gz
#
#
#
# EXECUTION COMMANDS
#
# Execution command:  ${HOME}/tasks/mysql_backup.sh
# (to disable output)  ${HOME}/tasks/mysql_backup.sh > /dev/null
#
#
#
# Phil Rae, https://github.com/iamphilrae
# Author:
#
##



###################
#
# CHANGELOG
#
# 1.0
# -----
# Initial release.
#
#





###################
# 
# VARIABLES
#

SCRIPT_VERSION="v1"

# Place to store backups, either a separate disk or a network mount
DEST="${HOME}/backups"

# Databases to exclude from backups
EXCLUDE="test information_schema"

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
echo "Beginning MySQL Backup Script $SCRIPT_VERSION"
echo "$NOW"
echo


MYSCRIPT="$(basename $0)"
TARPATH="/bin/gtar"
EXTRAFLAGS=""
# File to store current backup file
FILE=""
# Store list of databases
DBS=""
# Linux bin paths, change this if it can not be autodetected via which command
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"



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

# Get all database list first
DBS="$($MYSQL -u $DB_USER -h $DB_HOST -p$DB_PASS -Bse 'show databases')"


# Loop through databases, dumping them to files
for DB in $DBS
do
	skipdb=-1

	if [ "$EXCLUDE" != "" ]; then
		for i in $EXCLUDE
		do
		  [ "$DB" == "$i" ] && skipdb=1 || :
		done
	fi
	
	if [ "$skipdb" == "-1" ] ; 
	then		
		
		FILE_PREFIX="${HOSTNAME//./-}__MYSQL__"
		FILE_POSTFIX="__${LOGNAME}__${DB}.sql.gz"
		
		FILENAME_LATEST="${FILE_PREFIX}latest${FILE_POSTFIX}"
		FILENAME_DAILY="${FILE_PREFIX}daily-$(date +%d)${FILE_POSTFIX}"
		FILENAME_MONTHLY="${FILE_PREFIX}monthly-$(date +%m)${FILE_POSTFIX}"
		FILENAME_YEARLY="${FILE_PREFIX}yearly-$(date +%Y)${FILE_POSTFIX}"
		
	
		$MYSQLDUMP -u $DB_USER -h $DB_HOST -p$DB_PASS $DB | $GZIP -9 > ${DEST}/${FILENAME_LATEST}
		$MYSQLDUMP -u $DB_USER -h $DB_HOST -p$DB_PASS $DB | $GZIP -9 > ${DEST}/${FILENAME_DAILY}
		$MYSQLDUMP -u $DB_USER -h $DB_HOST -p$DB_PASS $DB | $GZIP -9 > ${DEST}/${FILENAME_MONTHLY}
		$MYSQLDUMP -u $DB_USER -h $DB_HOST -p$DB_PASS $DB | $GZIP -9 > ${DEST}/${FILENAME_YEARLY}
		
		echo Backed up: $DB

	else
	
		echo Skipping: $DB

	fi
done



echo
echo "Backup complete!" 
echo "Backup location: $S3_BUCKET"
echo
echo "__________________________________________"
echo "=========================================="
echo
echo