#!/bin/sh

# Run the script only as a certain user

if [[ $EUID -ne 751 ]]; then
   echo "This script should be run only automatically as user with UID 751!"
   exit 1
fi

# Define all variables
DIR=/opt/software
HOSTNAME=$(hostname)
DATE=$(date +%Y-%m-%d)
NFS=/mnt/$HOSTNAME
PROG_NAME=$(basename $0)

case "$HOSTNAME" in
	server1)
			FOLDERS=(
				$DIR/log/archive \
         			$DIR/log2/archive
				)
			;;
	server2)
                        FOLDERS=(
				$DIR/log/archive \
                                $DIR/log2/archive
        			)
                        ;;
esac

# Daily file rotation for a file that is constantly in use.
case "$HOSTNAME" in
	server3)
		       FILE=$DIR/somedir/somefile.debug
		       SIZE=$(stat -c%s ${FILE})
		       if ! [ $SIZE = 0 ]; then
					       echo "Rotating file to ${FILE}.$DATE"
                       			       cp ${FILE} ${FILE}.$DATE
                       		               cat /dev/null > ${FILE}
					       echo "Compressing ${FILE}.$DATE to ${FILE}.$DATE.gz"
                       			       gzip ${FILE}.$DATE
		       fi
			
		       find $DIR/COMP/log/gc -name \*.log -mtime +2 -exec echo Compressing {} and moving it to $NFS/COMP/gc \; -exec gzip {} \; -exec mv {}\.gz $NFS/COMP/gc \;
                       ;;
esac

# Compress files and then move them to NAS

for i in ${FOLDERS[@]}; do
                          DIR=$(echo $i |cut -d/ -f7)

                          # PROCEED ONLY IF FOLDER IS NOT ALREADY EMPTY
                          if ! [ ! "$(ls -A $i)" ]; then
                                                        for j in $i/*; do
                                                                         # COMPRESS LOGS AND IGNORE ALREADY COMPRESSED FILES/IGNORE ignore_dir directory/COMPRESS FILES LAST MODIFIED OVER 2 DAYS AGO
                                                                         if ! [[ $i = "${DIR}/ignore_dir/log" ]] && ! [[ $j =~ \.gz$ ]]; then
                                                                                                     find $j -mtime +1 -exec echo Compressing {} \; -exec gzip {} \;
                                                                         fi
                                                        done

                                                        for j in $i/*; do
                                                                         # Move compressed logs to NAS 
                                                                         if [[ $j =~ \.gz$ ]]; then
                                                                                                   # Move file ONLY if the file with the same name does not already exist
                                                                                                   NAME=$(basename $j)
                                                                                                   if ! [ -f $NFS/$DIR/$NAME ]; then
                                                                                                                                                   echo "Moving $j to $NFS/$DIR"
                                                                                                                                                   mv $j $NFS/$DIR
                                                                                                   else
                                                                                                       echo "File $j already exists in $NFS/$DIR"
                                                                                                   fi
                                                                         fi
                                                        done
                          fi
done


# FIND all files in /mnt/${HOSTNAME} directory and delete them if they are over 100 days old

find $NFS/* -mtime +100 -name '*.gz' -exec echo Removing {} \; -exec rm {} \;

# APPEND TIME TO THE rotation.log
echo "$PROG_NAME: Completed on `date`"
