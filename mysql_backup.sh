#!/bin/sh

# Initiate variables
MYSQL_DATABASE="${MYSQL_DATABASE}"
MYSQL_USER="${MYSQL_USER}"
MYSQL_HOST="${MYSQL_HOST}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
MYSQL_OPTIONS="${MYSQL_OPTIONS}"
BACKUP_PATH="${BACKUP_PATH:=/backup}"
KEEP_FILES="${KEEP_FILES:=0}"

parse_args() {
  ### Parse first agrument
  if [ "$#" -ge 1 ]; then
    ACTION="$1"
    shift
  fi

  ### Parse other agruments
  while [ "$#" -gt 1 ]; do
  key="$1"
    case $key in
      -d|--database)
      MYSQL_DATABASE="$2"
      shift
      ;;
      -u|--user)
      MYSQL_USER="$2"
      shift
      ;;
      -h|--host)
      MYSQL_HOST="$2"
      shift
      ;;
      -p|--password)
      MYSQL_PASSWORD="$2"
      shift
      ;;
      --opts)
      MYSQL_OPTIONS="$2"
      ;;
      -f|--file)
      BACKUP_FILE="$2"
      ;;
      --backup_path)
      BACKUP_PATH="$2"
      ;;
      -k|--keep_files)
      KEEP_FILES="$2"
      ;;
      *)
        # unknown option
      ;;
    esac

  shift
  done
}

show_help() {
  echo << EOF
  Usage: mysql_backup.sh backup|restore [args]
EOF
}

show_error() {
  echo ""
  echo "ERROR: ${1}"
  echo ""
  exit 1
}

check_args() {
  case "$ACTION" in
      backup | b )
          [ "$ACTION" = 'b' ] && ACTION='backup'
      ;;
      restore | r )
          [ "$ACTION" = 'r' ] && ACTION='restore'
      ;;
  esac

  [ -z "$MYSQL_HOST" ] && show_error "MYSQL_HOST must be specified"
  [ -z "$MYSQL_USER" ] && show_error "MYSQL_USER must be specified"
  [ -z "$BACKUP_FILE" ] && show_error "BACKUP_FILE must be specified"

  if [ "$ACTION" = "restore" ]; then
    [ -z "$MYSQL_DATABASE" ] && show_error "MYSQL_DATABASE myst be specified for restore option"
  fi
}

dbdump () {
  # concatinate arguments with MYSQL_DATABASE
  if [ -z "$MYSQL_DATABASE" ]; then
    MYSQL_OPTIONS="--all-databases $MYSQL_OPTIONS"
  else
    MYSQL_OPTIONS="-B $MYSQL_DATABASE $MYSQL_OPTIONS"
  fi

  # check or create backup PATH
  if [ ! -z "$BACKUP_PATH" ]; then
    if [ ! -d "$BACKUP_PATH" ]; then
      mkdir -p $BACKUP_PATH
    fi
    FILENAME=$BACKUP_PATH/$BACKUP_FILE.bz2
  else
    FILENAME=$BACKUP_FILE.bz2
  fi

  echo "Trying to backup database at ${MYSQL_HOST} to ${FILENAME} ..."
  echo "mysqldump --user=$MYSQL_USER --password=$MYSQL_PASSWORD --host=$MYSQL_HOST $MYSQL_OPTIONS > $FILENAME"
  mysqldump --user=$MYSQL_USER --password=$MYSQL_PASSWORD --host=$MYSQL_HOST $MYSQL_OPTIONS | bzip2 > $FILENAME
  if [ 0 -eq $? ]; then
    FILESIZE=$(stat -c%s "$FILENAME")
    echo "Backup file $FILENAME has been created. Filesize: $(( FILESIZE / 1024 )) KB"
  else
    show_error "Failed to create backup. Exiting ..."
  fi

  # remove redundant files
  if [ -d "$BACKUP_PATH" -a $KEEP_FILES -gt 1 ]; then
    echo "Checking for redundant files ..."
    cd $BACKUP_PATH
    REMOVED=$(ls -t | awk "NR>$KEEP_FILES")
    if [ ! -z "$REMOVED" ]; then
     echo "Removing redundant files ..."
     rm -f $REMOVED
    else
      echo "Nothing to remove"
    fi
  fi
}

dbrestore() {
  # check backup PATH
  if [ ! -z "$BACKUP_PATH" ]; then
    FILENAME=$BACKUP_PATH/$BACKUP_FILE.bz2
  else
    FILENAME=$BACKUP_FILE.bz2
  fi

  [ ! -f "$FILENAME" ] && show_error "File to restore ''$FILENAME' not found"

  echo "Trying to restore database(s) at ${MYSQL_HOST} from ${FILENAME} ..."
  echo "bunzip2 < $FILENAME. | mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --host=$MYSQL_HOST  $MYSQL_OPTIONS $MYSQL_DATABASE"
  bunzip2 < $FILENAME | mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --host=$MYSQL_HOST  $MYSQL_OPTIONS $MYSQL_DATABASE
  if [ 0 -eq $? ]; then
      echo "Database resore has been completed"
  else
      show_error "Failed to restore database"
  fi
}

if [ -f "$0" ]; then
  parse_args $@
  check_args
  echo $ACTION
  if [ "$ACTION" = "backup" ]; then
    dbdump
  elif [ "$ACTION" = "restore" ]; then
    dbrestore
  else
    show_error "Unknown action"
  fi

  exit 0
fi
