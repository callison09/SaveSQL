#!/bin/bash

#Local directory and file info
DUMP_DIR=/**YourDirectory**
DUMP_SUBDIR=`date +%m`
ARCHIVE_NAME=`date +%d`

#Remote directory for upload
REMOTE_USER=**YourRemoteUsername**
REMOTE_IP=**YourRemoteIP**
REMOTE_DIR=/**YourRemoteDirectory**

#MySQL
mUSER=**YourMySQLUser**
mPASS=**YourPassword**

#Format Output - to make things perty
fout()
{
  SP='.'
  S1=${#1}
  S2=${#2}
  C_SIZE=72
  SP_SIZE=$((C_SIZE-S1))
  while [ $SP_SIZE -gt 0 ]
  do
    SP+='.'
    SP_SIZE=$((SP_SIZE-1))
  done
  echo -e "$1" "$SP" "$2"
}

#Other Globals
ROOT_UID=0     # Only users with $UID 0 have root privileges.
LINES=50       # Default number of lines saved.
E_XCD=86       # Can't change directory?
E_NOTROOT=87   # Non-root exit error.

#Colors
COFF="\033[0m" #color off
BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
BROWN="\033[33m"
BLUE="\033[34m"
MAGE="\033[35m"
CYAN="\033[36m"
GRAY="\033[37m"

# Run as root, of course.
if [ "$UID" -ne "$ROOT_UID" ]
then
  echo "Must be root to run this script."
  exit $E_NOTROOT
fi  

#check directory exsistance
if [ ! -d "${DUMP_DIR}/${DUMP_SUBDIR}" ]
then
  echo -e "Making directory... [${CYAN}${DUMP_DIR}/${DUMP_SUBDIR}${COFF}]"
  sleep 1
  if MakeDir=`mkdir "${DUMP_DIR}/${DUMP_SUBDIR}"`
  then
    fout "Directory creation" "[${GREEN}ok${COFF}]"
  else
    fout "Directory creation" "[${RED}fail${COFF}]"
  fi
else
  echo -e "Skipping directory creation for ${DUMP_DIR}/${DUMP_SUBDIR}"
fi

sleep 1

#Get database names
if DBS=`mysql --user="$mUSER" --password="$mPASS" -Bse 'show databases'`
then
  fout "Getting database names" "[${GREEN}ok${COFF}]"
else
  fout "Getting database names" "[${RED}fail${COFF}]"
fi

sleep 1

#loop each database name, dumping database into .sql file
for DB in $DBS
do
  FILENAME="${DUMP_DIR}/${DUMP_SUBDIR}/${DB}-`date +%m-%d-%y`.sql"
  if DUMP=`mysqldump --user="$mUSER" --password="$mPASS" "$DB" > "$FILENAME"`
  then
    fout "Saving ${FILENAME}" "[${GREEN}ok${COFF}]"
  else
    fout "Saving ${FILENAME}" "[${RED}fail${COFF}]"
  fi
  sleep 0.25
done

#Add to archive.
if ADD=`tar czPf "$DUMP_DIR"/"$DUMP_SUBDIR"/"$ARCHIVE_NAME".tar.gz "$DUMP_DIR"/"$DUMP_SUBDIR"/*.sql`
then
  fout "Gathering sql files" "[${GREEN}ok${COFF}]"
  sleep 1
  fout "Compressing sql files" "[${GREEN}ok${COFF}]"
else
  fout "Gathering sql files" "[${RED}fail${COFF}]"
fi

sleep 1

#Clean up .sql files
if RM=`rm "$DUMP_DIR"/"$DUMP_SUBDIR"/*.sql`
then
  fout "Cleaning up sql files" "[${GREEN}ok${COFF}]"
else
  fout "Cleaning up sql files" "[${RED}fail${COFF}]"
fi

sleep 1

#Copy to remote server using passphraseless/passwordless ssh keys
if SCP=`scp -P 22 -i /root/.ssh/id2_rsa "$DUMP_DIR"/"$DUMP_SUBDIR"/"$ARCHIVE_NAME".tar.gz "$REMOTE_USER"@"$REMOTE_IP":"$REMOTE_DIR"/"$DUMP_SUBDIR"_"$ARCHIVE_NAME".tar.gz`
then
  fout "Copying to remote server" "[${GREEN}ok${COFF}]"
else
  fout "Copying to remote server" "[${RED}fail${COFF}]"
fi

sleep 0.75

echo -e "[${GREEN}All Done${COFF}]"
exit
