# mysql-and-file-backup-scripts
Simple shell scripts for backing up MySQL and Web Files via cron jobs. Includes functionality to push backups to AWS S3.

## Overview

There are three tasks that can be run which are:

* Web Files Backup
* MySQL Databases Backup
* Push Backups to AWS S3

These three tasks are to be run by cron jobs and are independant of each other so you can select what you want to run, when you want to run them.


## Installation

Simply copy all the files within the `src` directory into a `tasks` folder in the home folder of your server (defined below as *{HOME}*). This *tasks* folder should absolutely **not** be  inside your public_html folder - it should be the level above at least.

## Configuration

The three scripts all contain their own minor configuration settings:

##### Web Files Backup

Configuration is set within `file_backup.php`:

* Folder sources (SOURCES_XXX)
* Destination folder (DEST)
* Exclusions (EXCLUDE)

##### MySQL Databases Backup

Configuration is set within `mysql_backup.php`:

* Database host (DB_HOST - usually *localhost*)
* Database username (DB_USER)
* Database password (DB_PASS)

##### Push to AWS S3

Configuration is set within `config/push_to_s3.php`:

* Server account username (server_account)
* AWS Access Key (access_key)
* AWS Access Secret (access_secret)
* AWS Bucket to store the backups in (backup bucket)
* Folder within the AWS bucket to store backups (backup_folder)


## Usage

The following commands can be run directly on the command line, however for an automated backup proceedure, they should be run as cronjobs.

#### Web Files Backup

```bash
# Execute with output
${HOME}/tasks/file_backup.sh

# Execute with disabled output
${HOME}/tasks/file_backup.sh > /dev/null
```

#### MySQL Databases Backup

```bash
# Execute with output
${HOME}/tasks/mysql_backup.sh

# Execute with disabled output
${HOME}/tasks/mysql_backup.sh > /dev/null
```


## Timings

The two backup scripts are recommended to be run at least once per day. The MySQL Databases backup script should possibly run more frequently (hourly?) due to the nature of databases being changed much more frequently than files.

Although both scripts can be run multiple times per day, due to the fixed (by design) filename structures, files generated during the same day will overwrite the previous ones from the same day.

As daily and monthly files will eventually consist of the same filename (e.g. 30th April and 30th May, or April 2015 and April 2016), these files will naturally overwrite each other. The exception being the yearly backup which following 31st December backup in a particular year, it will never be overwritten again, therefore providing a permenant snapshot for that year.


## What is Backed Up

### Web Files

An entire directory (as specified) of a web server will be backed up as a four ZIP files. The default configuration is to backup the *public_html* folder. These four files will be saved upon each execution of the script:

**Latest backup named after username and overwritten daily**
`hostname__FILES__latest__username__directory.tar.gz`

**Daily backups named after days of the month and rotated monthly**
`hostname__FILES__daily-DD__username__directory.tar.gz`

**Monthly backups named after days of the month and rotated yearly**
`hostname__FILES__monthly-MM__username__directory.tar.gz`

**Yearly backups named after year and never rotated**
`hostname__FILES__yearly-YYYY__username__directory.tar.gz`
*(Note: will always be the latest backup until 31st December)*


## MySQL Databases

All databases for a particular database account will be backed up as a four ZIP files. These four files will be saved upon each execution of the script:

**Latest backup named after username and overwritten daily**
`hostname__MYSQL__latest__username__database.tar.gz`

**Daily backups named after days of the month and rotated monthly**
`hostname__MYSQL__daily-DD__username__database.tar.gz`

**Monthly backups named after days of the month and rotated yearly**
`hostname__MYSQL__monthly-MM__username__database.tar.gz`

**Yearly backups named after year and never rotated**
`hostname__MYSQL__yearly-YYYY__username__database.tar.gz`
*(Note: will always be the latest backup until 31st December)*


## File Handling

Backups are by default stored in the folder `{HOME}/backups/`, a value which is configurable within the two backup scripts (see above).

Included with these scripts is a Push to AWS S3 PHP-based script which will push these files to your chosen S3 bucket, removing the original backup files in the process.

Pushing to S3 is not a requirement and is only necessary as extra off-site redundancy should the standard backups for the server's storage fail.


